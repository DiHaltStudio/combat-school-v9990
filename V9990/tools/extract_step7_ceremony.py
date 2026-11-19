#!/usr/bin/env python3
"""Graduation ceremony assets from a per-frame MAME capture of the arcade
ending (make capture-step7-ceremony: snapshots of frames 1900..2460).

The arcade scrolls one tall picture: the stage at the bottom, sky with the
flagpole, and the flag at the top, 2 pixels per frame for 256 frames
(512 pixels), while eight caps rise from the stage and leave at the top.
Then the flag waves with four pictures of about 10 frames each.

Writes to assets/step7-ending:
  ceremony.png   256x724: the scene, rows 9..732 of the arcade picture (the
                 same 212-row window as the other ending screens); rows
                 0..211 are wave frame 0
  wave1..3.png   the other waving pictures (256x212)
  cap0..7.png    the eight cap pictures (rotation), transparent background
  caps.json      {"scroll_start": frame, "tracks": [[start, x, y, [[sprite,
                 dx, dy], ...]], ...]}: arcade screen coordinates of each
                 cap from its first frame, one entry per following frame
"""
import glob, hashlib, collections, json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

CAPTURE = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/step7/ceremony-mame')
OUT = Path('assets/step7-ending')
FIRST = 1900                     # frame of the first snapshot
CROP = 9                         # first arcade row of the 212-row window
CAP_COLOURS = np.array([(33, 49, 33), (214, 165, 115), (140, 123, 90),
                        (99, 82, 33), (90, 74, 66), (231, 231, 231)])

files = sorted(glob.glob(str(CAPTURE / 'combatsc' / '*.png')))
frames = [np.asarray(Image.open(f).convert('RGB')).astype(int) for f in files]
assert len(frames) > 500, len(frames)

# Vertical scroll between consecutive frames, from the flagpole and trees.
offset = [0]
for a, b in zip(frames, frames[1:]):
    best = min(range(5), key=lambda d: np.abs(a[16:200 - d, 0:40] - b[16 + d:200, 0:40]).mean())
    offset.append(offset[-1] + best)
moving = [i for i in range(1, len(offset)) if offset[i] != offset[i - 1]]
scroll_start, scroll_end = moving[0] - 1, moving[-1]
assert offset[-1] == 512 and scroll_end - scroll_start == 256, (offset[-1], scroll_start, scroll_end)

# The scene: median of every frame at its scroll position (removes the caps).
rows = [[] for _ in range(736)]
for i in range(scroll_start - 20, scroll_end + 1):
    top = 512 - offset[i]
    for y in range(224):
        rows[top + y].append(frames[i][y])
scene = np.stack([np.median(np.array(r), axis=0) for r in rows]).astype(np.uint8)

# Waving: the four distinct pictures after the caps have gone.
waves, seen = [], set()
for a in frames[-60:]:
    key = hashlib.md5(a[CROP:CROP + 212].tobytes()).hexdigest()
    if key not in seen:
        seen.add(key)
        waves.append(a[CROP:CROP + 212].astype(np.uint8))
assert len(waves) == 4, len(waves)

def cap_mask(a):
    m = np.zeros(a.shape[:2], bool)
    for c in CAP_COLOURS:
        m |= np.abs(a - c).sum(2) == 0
    return m

# The eight cap pictures: the most frequent isolated blobs.
first_cap = scroll_start + 3
count, shapes = collections.Counter(), {}
for a in frames[first_cap:]:
    m = cap_mask(a)
    lab, _ = ndimage.label(ndimage.binary_dilation(m))
    for k, sl in enumerate(ndimage.find_objects(lab)):
        sub = m[sl] & (lab[sl] == k + 1)
        if sub.sum() < 5 or sub.shape[0] > 17 or sub.shape[1] > 17:
            continue
        ys, xs = np.nonzero(sub)
        sub = sub[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        region = a[sl][ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        img = np.where(sub[..., None], region, 0).astype(np.uint8)
        key = hashlib.md5(img.tobytes() + bytes(img.shape[:2])).hexdigest()
        count[key] += 1
        shapes[key] = img
caps = [shapes[k] for k, _ in count.most_common(8)]

# Each frame as caps (picture, x, y): place pictures over the cap pixels.
def decompose(a):
    m = cap_mask(a)
    left, found = m.copy(), []
    for _ in range(16):
        ys, xs = np.nonzero(left)
        if len(ys) < 5:
            break
        y0 = ys.min(); x0 = xs[ys == y0].min()
        best = None
        for j, t in enumerate(caps):
            tm = t.sum(2) > 0
            h, w = tm.shape
            X, Y = x0 - np.nonzero(tm[0])[0][0], y0
            ya, xa = max(Y, 0), max(X, 0)
            yb, xb = min(Y + h, a.shape[0]), min(X + w, a.shape[1])
            if yb <= ya or xb <= xa:
                continue
            sub = tm[ya - Y:yb - Y, xa - X:xb - X]
            hit = (np.abs(a[ya:yb, xa:xb] - t[ya - Y:yb - Y, xa - X:xb - X].astype(int)).sum(2) == 0) & sub
            score = hit.sum() / max(1, sub.sum())
            if best is None or score > best[0]:
                best = (score, j, X, Y, sub, ya, xa, yb, xb)
        score, j, X, Y, sub, ya, xa, yb, xb = best
        left[ya:yb, xa:xb] &= ~sub
        if score > 0.6:
            found.append((j, int(X), int(Y)))
        else:
            left[y0, x0] = False
    return found

per_frame = [decompose(a) for a in frames[first_cap:]]

# Tracks: nearest cap in the next frame, at most 2 pixels away on each axis.
tracks = []
for f, found in enumerate(per_frame):
    live = [t for t in tracks if t['last'] == f - 1]
    pairs = sorted((abs(X - t['x']) + abs(Y - t['y']), ti, k)
                   for ti, t in enumerate(live) for k, (j, X, Y) in enumerate(found)
                   if abs(X - t['x']) <= 2 and abs(Y - t['y']) <= 2)
    used_t, used_c = set(), set()
    for _, ti, k in pairs:
        if ti in used_t or k in used_c:
            continue
        used_t.add(ti); used_c.add(k)
        t = live[ti]; j, X, Y = found[k]
        t['steps'].append([j, X - t['x'], Y - t['y']])
        t['x'], t['y'], t['last'] = X, Y, f
    for k, (j, X, Y) in enumerate(found):
        if k not in used_c:
            tracks.append({'start': f, 'x0': X, 'y0': Y, 'j0': j, 'x': X, 'y': Y, 'last': f, 'steps': []})
tracks = [t for t in tracks if len(t['steps']) >= 4]

OUT.mkdir(parents=True, exist_ok=True)
picture = scene[CROP:CROP + 724].copy()
picture[:212] = waves[0]
Image.fromarray(picture).save(OUT / 'ceremony.png')
for k, w in enumerate(waves[1:], 1):
    Image.fromarray(w).save(OUT / f'wave{k}.png')
for j, t in enumerate(caps):
    alpha = (t.sum(2) > 0).astype(np.uint8) * 255
    Image.fromarray(np.dstack([t, alpha]), 'RGBA').save(OUT / f'cap{j}.png')
json.dump({'scroll_start': scroll_start + FIRST, 'first_cap': first_cap + FIRST,
           'tracks': [[t['start'] + 3, t['x0'], t['y0'], t['j0'], t['steps']] for t in tracks]},
          open(OUT / 'caps.json', 'w'))
print(f'scroll frames {scroll_start + FIRST}..{scroll_end + FIRST}, {len(tracks)} cap tracks, '
      f'{sum(len(t["steps"]) + 1 for t in tracks)} cap frames, cap sizes {[c.shape[:2] for c in caps]}')
