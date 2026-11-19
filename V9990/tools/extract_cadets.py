#!/usr/bin/env python3
"""The arcade's running cadets after the Iron-Man bonus (before the map and
Firing Range II), from the MAME capture of tools/mame_range2_capture.lua.

usage: extract_cadets.py [capture dir, default build/mame-range2]

The scene starts at capture frame 9428 (T = 0, the barracks appear) and ends
at 10004 (576 frames, the length of arcade song 27h). Every actor is a 32x32
upper body with legs below, moving right at a constant speed:
  - the sergeant (circuit 0, colour 2): 1.5 px per frame, from T = 4;
  - ten cadets (circuit 0, colour 0): 1.5 px per frame, in a loose pack;
  - the player (circuit 1, colour 1): 1 px per frame, from T = 160, alone.
Each kind cycles through six poses in a fixed number of frames.

Writes assets/step3-transition/cadets.png (atlas: 15 cells of 32x48, eight
per row: cadet 0-4, sergeant 5-9, player 10-14) and cadets.json (cycles and
actors, with x in pixels and y in rows of the 212-line screen) for
tools/build_step3_transition.py.
"""
import json
import sys
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_sprites

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/mame-range2')
OUT = Path('assets/step3-transition')
T0, T1 = 9428, 10004
SCREEN_Y = 28                  # sprite RAM y -> row of the 212-line screen

# kind: circuit, palette group, colour-bank byte, sprite attr of top / legs,
# poses {name: (top code, [(leg dx, leg code)])}, frames per pose, x speed in
# half pixels per frame.
KINDS = {
    'cadet': dict(circuit=0, group=0, bank=0x00, top=0xc8, legs=0xc0, speed=3,
                  poses={0: [(8, 28)], 4: [(0, 20), (16, 21)], 8: [(0, 22), (16, 23)],
                         12: [(0, 24), (16, 25)], 16: [(0, 26), (16, 27)]}),
    'sergeant': dict(circuit=0, group=0, bank=0x02, top=0x88, legs=0x80, speed=3,
                     poses={32: [(0, 48), (16, 49)], 36: [(0, 50), (16, 51)],
                            40: [(0, 52), (16, 53)], 44: [(0, 54), (16, 55)]}),
    'player': dict(circuit=1, group=4, bank=0x10, top=0x88, legs=0x80, speed=2,
                   poses={28: [(8, 53)], 32: [(0, 22), (16, 23)], 36: [(0, 54), (16, 55)],
                          40: [(0, 56), (16, 57)], 44: [(0, 98), (16, 99)]}),
}
UPRIGHT = 29                   # the sergeant's three 16x16 sprites 29-31, 8 px right


def ram(frame, circuit):
    data = (SRC / f'frame-{frame}' / f'videoram{circuit}.bin').read_bytes()[0x1800:0x1d00]
    for i in range(64):
        num, bank, sy, sx, attr = data[i * 5:i * 5 + 5]
        if attr & 1:
            sx -= 256
        if sx > -32 and not (num == 0 and attr == 6):
            yield num, bank, sy, sx, attr


def sprite(frame, circuit, group, x, y, code):
    """One sprite of a capture frame, as 32x32 RGBA from its origin."""
    image = arcade_sprites.render(SRC / f'frame-{frame}', circuit, None, (x, y, x + 1, y + 1), group, {code})
    out = Image.new('RGBA', (32, 32))
    out.paste(image.crop((max(x, 0), y, max(x, 0) + 32, y + 32)), (max(x, 0) - x, 0))
    return out


def observations(kind):
    """[(T, x, y, pose)] of every actor of a kind; pose is a top code or UPRIGHT."""
    k = KINDS[kind]
    seen = []
    for f in range(T0, T1, 4):
        for num, bank, sy, sx, attr in ram(f, k['circuit']):
            if bank != k['bank']:
                continue
            if attr & 14 == 8 and num in k['poses']:
                seen.append((f - T0, sx, sy, num, f))
            elif kind == 'sergeant' and num == UPRIGHT:
                seen.append((f - T0, sx - 8, sy, UPRIGHT, f))
    return seen


def pose_cells():
    """Atlas cells: each pose drawn from the first frame that shows it."""
    cells = {}
    for kind, k in KINDS.items():
        for t, x, y, pose, f in observations(kind):
            if (kind, pose) in cells or x < 0:
                continue
            cell = Image.new('RGBA', (32, 48))
            if pose == UPRIGHT:
                for i in range(3):
                    part = sprite(f, 0, 0, x + 8, y + 16 * i, UPRIGHT + i)
                    cell.paste(part.crop((0, 0, 32, 16)), (8, 16 * i), part.crop((0, 0, 32, 16)))
            else:
                top = sprite(f, k['circuit'], k['group'], x, y, pose)
                cell.paste(top, (0, 0), top)
                for dx, code in k['poses'][pose]:
                    leg = sprite(f, k['circuit'], k['group'], x + dx, y + 32, code)
                    cell.paste(leg.crop((0, 0, 32, 16)), (dx, 32), leg.crop((0, 0, 32, 16)))
            cells[(kind, pose)] = cell
    return cells


def tracks(kind):
    """Actors of a kind: [(first T, x at that T, y, [(T, pose)])]."""
    speed = KINDS[kind]['speed']
    found = {}
    for t, x, y, pose, f in observations(kind):
        key = (y, 2 * x - speed * t)          # constant along an actor's path
        found.setdefault(key, []).append((t, pose))
    out = []
    for (y, x2), seen in found.items():
        t = seen[0][0]
        out.append((t, (x2 + speed * t) // 2, y, seen))
    return sorted(out)


def fit_cycle(kind, order):
    """Frames per whole cycle and each actor's offset: the best match to what
    the capture shows, for a six-pose cycle in `order`. The pose at T is
    order[(6 * (T + offset) // period) % 6], which the Z80 follows with one
    accumulator per kind (add 6 each frame, a pose step at each period)."""
    best = None
    for period in range(18, 49):
        offsets, score = [], 0
        for t0, x0, y, seen in tracks(kind):
            hits = [sum(order[6 * (t + o) // period % 6] == pose for t, pose in seen) for o in range(period)]
            offsets.append(max(range(period), key=hits.__getitem__))
            score += max(hits)
        if best is None or score > best[0]:
            best = (score, period, offsets)
    return best


def main():
    cells = pose_cells()
    order = {'cadet': [8, 0, 12, 16, 0, 4], 'sergeant': [32, 36, UPRIGHT, 40, 44, UPRIGHT],
             'player': [40, 44, 28, 32, 36, 28]}
    names = {'cadet': [0, 4, 8, 12, 16], 'sergeant': [32, 36, 40, 44, UPRIGHT], 'player': [28, 32, 36, 40, 44]}
    atlas = Image.new('RGBA', (256, 96))
    index = {}
    for n, (kind, pose) in enumerate((k, p) for k in names for p in names[k]):
        atlas.paste(cells[(kind, pose)], ((n % 8) * 32, (n // 8) * 48))
        index[(kind, pose)] = n
    OUT.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT / 'cadets.png')
    scene = {'frames': T1 - T0, 'kinds': {}, 'actors': []}
    for kind in names:
        score, period, offsets = fit_cycle(kind, order[kind])
        total = sum(len(s) for *_, s in tracks(kind))
        print(f'{kind}: a cycle every {period} frames, {score}/{total} poses match')
        scene['kinds'][kind] = {'speed_half_px': KINDS[kind]['speed'], 'cycle_frames': period,
                                'cycle': [index[(kind, p)] for p in order[kind]]}
        for (t0, x0, y, seen), offset in zip(tracks(kind), offsets):
            scene['actors'].append({'kind': kind, 'start': t0, 'x': x0, 'y': y - SCREEN_Y, 'offset': offset})
    # Back to front: the arcade's lower rows are nearer.
    scene['actors'].sort(key=lambda a: a['y'])
    (OUT / 'cadets.json').write_text(json.dumps(scene, indent=1) + '\n')
    print(len(scene['actors']), 'actors')


if __name__ == '__main__':
    main()
