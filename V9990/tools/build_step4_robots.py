#!/usr/bin/env python3
"""Step 4 robots from the arcade itself (18-nov), replacing the trajectories
that tools/build_step4_recorded_sequence.py guessed from a video.

The video tracker followed the magenta panels, which blink, so robots
vanished for a few frames, came back with another ID or were dropped. Here
the source is MAME: tools/capture_step4_robots.lua prints every circuit-0
sprite (the robots) of every frame of Step 4 without firing, kept in
../local-inputs/robots-mame.txt.gz.

- Identity: each frame is matched to the previous one by the sprite's
  bottom-centre (the feet stay put when the code changes size), with an
  "unmatched" option, so a robot that leaves never steals another's ID.
  75 robots, none appears or vanishes in mid-field except where the arcade
  does it (at the horizon).
- Time: the arcade moves the robots every 2 frames (odd frames), i.e. 30 Hz,
  the rate of the ROM's table. MAME frame 10237 (the first robot) is the
  table's frame 32, as in the video recording; the table keeps 1380 frames.
- Size: the ROM's image (five per view, target-sets.bin) whose height is
  closest to the arcade sprite's visible height. It goes in the view byte
  (bits 2-4, size + 1), so the ROM never picks it from the y: picked by the
  top line, a robot crossing a band boundary jumped up to 16 lines.
- Place: the ROM's field is the arcade's screen 12 lines up
  (tools/build_step4_visual.py), and a sprite at y sits at screen y - 16,
  so the ROM y = sprite y - 28. The ROM draws its own images (five sizes by
  depth), so each is put with its feet and centre where the arcade
  sprite's visible pixels have them.
- View: arcade codes front (and three-quarter) -> 0, side -> 1 facing right
  or 2 flipped (facing left), rear -> 3 (drawn as front, view_sets).

Output: assets/step4/robot-paths.json and recorded-sequence.json, the same format
(per frame: count, then id, x, y, view | (size + 1) << 2 per robot).

usage: build_step4_robots.py [log.gz] [target-sets.bin]"""
import gzip
import json
import sys
from pathlib import Path
import numpy as np
from scipy.optimize import linear_sum_assignment
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_codes

LOG = Path(sys.argv[1] if len(sys.argv) > 1 else '../local-inputs/robots-mame.txt.gz')
SETS = Path(sys.argv[2] if len(sys.argv) > 2 else 'build/step4/target-sets.bin')
OUT = Path('assets/step4')
FIRST, LAST = 10237, 12803          # MAME frames with robots (Step 4)
START = 32                          # table frame of MAME frame FIRST
FRAMES = 1380
FRONT = {144, 145, 146, 147, 148, 149, 150, 151, 152, 156, 160, 164, 180}
SIDE = {168, 188, 206, 209, 212}
REAR = {172, 200, 201, 204, 207, 210, 216}
VIEW_SET = (0, 1, 2, 0)                 # view_sets: rear drawn as front


_BOXES = {}


def visible(num, attr):
    if (num, attr) not in _BOXES:
        image = arcade_codes.entry(num, 1, attr, 0, bytes(2048), group=0, circuit=0)
        _BOXES[num, attr] = image.getbbox()
    return _BOXES[num, attr]


def load():
    frames = {}
    for line in gzip.open(LOG, 'rt'):
        part = line.split()
        f = int(part[1])
        frames[f] = []
        for s in part[2:]:
            slot, rest = s.split(':')
            code, at = rest.split('@')
            num, _, attr = code.split('/')
            num, attr = int(num), int(attr, 16)
            if num == 0:
                continue
            x, y = map(int, at.split(','))
            assert num in FRONT | SIDE | REAR, num
            view = 0 if num in FRONT else 3 if num in REAR else 2 if attr & 0x10 else 1
            # Visible box of the sprite (the feet are always its last row).
            x0, y0, x1, y1 = visible(num, attr)
            frames[f].append(dict(slot=int(slot), cx=x + (x0 + x1) / 2, by=y + y1,
                                  h=y1 - y0, view=view))
    return frames


def track(frames, limit=14):
    count, prev = 0, []
    for f in range(FIRST, LAST):
        cur = frames[f]
        ids = [None] * len(cur)
        if prev and cur:
            n, m = len(prev), len(cur)
            cost = np.array([[abs(p['cx'] - c['cx']) + abs(p['by'] - c['by']) + 3 * (p['slot'] != c['slot'])
                              for c in cur] for p in prev], float)
            # Square matrix with dummies: leaving a robot unmatched costs
            # `limit`, so the assignment never forces a wrong pair.
            full = np.full((n + m, n + m), float(limit))
            full[:n, :m] = np.where(cost <= limit, cost, 1e6)
            full[n:, m:] = 0
            for a, b in zip(*linear_sum_assignment(full)):
                if a < n and b < m and cost[a, b] <= limit:
                    ids[b] = prev[a]['id']
        for k, c in enumerate(cur):
            if ids[k] is None:
                ids[k] = count
                count += 1
            c['id'] = ids[k]
        prev = cur
    return count


def placed(sets, robot):
    """ROM x, y (top left) and size band: the ROM image whose height is
    closest to the arcade sprite's visible height, with its feet and centre
    where the arcade sprite has them."""
    row = sets[16 * VIEW_SET[robot['view']]:]
    sizes = [row[1 + 3 * band:4 + 3 * band] for band in range(5)]
    band = min(range(5), key=lambda b: (abs(sizes[b][2] - robot['h']), -b))
    w, _, h = sizes[band]
    x = round(robot['cx'] - w / 2)
    y = round(robot['by'] - 28 - h)
    return max(0, min(255, x)), max(0, min(164, y)), band


def main():
    sets = SETS.read_bytes()
    frames = load()
    count = track(frames)
    assert count < 128                  # one hit flag per ID (0xc980..0xc9ff)
    table = [[] for _ in range(FRAMES)]
    for k in range(START, FRAMES):
        f = FIRST + 2 * (k - START)
        if f >= LAST:
            break
        for robot in frames[f]:
            x, y, band = placed(sets, robot)
            # View in bits 0-1, size + 1 in bits 2-4 (target_size).
            table[k].append((robot['id'], x, y, robot['view'] | (band + 1) << 2))
    raw = bytearray()
    for row in table:
        assert len(row) <= 16
        raw.append(len(row))
        for entry in row:
            raw.extend(entry)
    assert len(raw) <= 32768
    (OUT / 'robot-paths.json').write_text(json.dumps(table, separators=(',', ':')) + '\n')
    (OUT / 'recorded-sequence.json').write_text(json.dumps({
        'fps': 30, 'frames': FRAMES, 'tracks': count, 'bytes': len(raw),
        'source': 'MAME, Step 4 sin disparos (tools/capture_step4_robots.lua, '
                  '../local-inputs/robots-mame.txt.gz), fotogramas 10237..12802',
        'note': 'Cada robot con su identidad del arcade; tools/build_step4_robots.py'},
        ensure_ascii=False, indent=2) + '\n')
    print(f'step 4 robots: {count} robots, {max(map(len, table))} at most, {len(raw)} bytes')


if __name__ == '__main__':
    main()
