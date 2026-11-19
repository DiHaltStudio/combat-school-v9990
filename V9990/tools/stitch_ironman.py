#!/usr/bin/env python3
"""Reconstruct the arcade iron man course from the CPU's camera.

Input: tools/mame_ironman_capture.lua (a screenshot every two frames). The
right lane (x=130..247) follows the CPU over the whole course. Consecutive
shots are registered by their vertical background shift; each course row is
the per-pixel mode of every shot that saw it, which removes runners and
moving objects. The water is animated by rotating four palette entries, so
pixels are compared as palette indices (from each frame's palette.bin) and
the result is coloured with the first frame's palette.
Output: build/ironman/course.png (top = goal), course-index.npy, shifts.csv.
"""
import csv
from pathlib import Path
import numpy as np
from PIL import Image

SRC = Path('build/mame-ironman/combatsc')
OUT = Path('build/ironman'); OUT.mkdir(parents=True, exist_ok=True)
X0, X1 = 130, 248          # CPU lane
Y0, Y1 = 24, 200           # rows used for registration (below HUD, above POWER)

shots = sorted(SRC.glob('*.png'))
dumps = sorted(SRC.parent.glob('frame-*'))
assert len(shots) == len(dumps)

def palette(dump):
    raw = (dump / 'palette.bin').read_bytes()
    out = []
    for i in range(len(raw) // 2):
        c = raw[2 * i] | raw[2 * i + 1] << 8
        out.append(tuple((((c >> s) & 31) << 3) | (((c >> s) & 31) >> 2) for s in (0, 5, 10)))
    return out

def indices(shot, dump):
    rgb = np.asarray(Image.open(shot).convert('RGB'))[:, X0:X1]
    lookup = {}
    for i, c in enumerate(palette(dump)):
        lookup.setdefault(c, i)
    key = (rgb[..., 0].astype(np.int32) << 16) | (rgb[..., 1].astype(np.int32) << 8) | rgb[..., 2]
    table = {(r << 16) | (g << 8) | b: i for (r, g, b), i in lookup.items()}
    flat = np.array([table.get(int(k), 255) for k in key.ravel()], np.int16)
    return flat.reshape(key.shape)

def without_sprites(image, dump):
    """Mark every K007121 sprite rectangle of both circuits as unknown (255),
    so the reconstruction keeps only the tile background."""
    for circuit in (0, 1):
        ram = (dump / f'videoram{circuit}.bin').read_bytes()[0x1800:0x1d00]
        for i in range(64):
            num, bank, sy, sx, attr = ram[i * 5:i * 5 + 5]
            if not (num | bank | sy | sx | attr):
                continue
            sx -= 256 if attr & 1 else 0
            w, h = {6: (8, 8), 4: (8, 16), 2: (16, 8), 0: (16, 16), 8: (32, 32)}.get(attr & 14, (8, 8))
            x0, y0 = sx - X0, sy - 16
            image[max(0, y0):max(0, y0 + h), max(0, x0):max(0, x0 + w)] = 255
    return image

frames = [indices(p, d) for p, d in zip(shots, dumps)]
masked = [without_sprites(f.copy(), d) for f, d in zip(frames, dumps)]
reference = palette(dumps[0])

def shift(a, b, near=None):
    """dy such that b[y] == a[y - dy] (the course moves down the screen).
    With `near`, only near-1..near+1 is tried (used when moving objects
    make the free search ambiguous)."""
    best = None
    for dy in (range(0, 13) if near is None else range(max(0, near - 1), near + 2)):
        diff = (a[Y0:Y1 - dy] != b[Y0 + dy:Y1]).mean()
        if best is None or diff < best[0]:
            best = (diff, dy)
    return best

offsets = [0]; rows = []
for i in range(1, len(frames)):
    err, dy = shift(frames[i - 1], frames[i])
    if err > 0.2 and rows:
        err, dy = shift(frames[i - 1], frames[i], rows[-1][1])
    offsets.append(offsets[-1] + dy)
    rows.append((shots[i].name, dy, round(float(err), 4)))
with (OUT / 'shifts.csv').open('w', newline='') as f:
    csv.writer(f).writerows([('shot', 'dy', 'mismatch'), *rows])

# World row w = offset + (Y1 - 1 - y) grows towards the goal.
total = offsets[-1] + (Y1 - Y0)
height = total
course = np.full((height, X1 - X0), 255, np.int16)
for w in range(height):
    samples = []
    for off, img in zip(offsets, masked):
        y = Y1 - 1 - (w - off)
        if Y0 <= y < Y1:
            samples.append(img[y])
    if samples:
        stack = np.stack(samples)
        course[height - 1 - w] = [np.bincount(col[col < 255]).argmax() if (col < 255).any() else 255
                                  for col in stack.T]
np.save(OUT / 'course-index.npy', course)
colours = np.array([reference[i] if i < len(reference) else (0, 0, 0) for i in range(256)], np.uint8)
Image.fromarray(colours[np.clip(course, 0, 255)]).save(OUT / 'course.png')
print('shots', len(frames), 'course rows', height, 'max mismatch', max(r[2] for r in rows))
