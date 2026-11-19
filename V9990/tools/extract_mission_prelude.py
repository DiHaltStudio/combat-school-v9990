#!/usr/bin/env python3
"""The two arcade screens before the mission, from a per-frame MAME capture
(make capture-mission-prelude: snapshots of frames 3600..4900).

1. "ATTENTION! TERRORISTS HAVE TAKEN OVER. SAVE THE HOSTAGES!", typed letter
   by letter on black, then two soldiers who salute (frames 3669..4224).
2. The mansion seen from above: explosions, flickering windows, flashing
   lights and the player walking up to the door (frames 4247..4619).
Each lasts as in the arcade, with 57 and 22 black frames before and 22
after the mansion.

Each screen is a background picture plus animated regions (connected areas
where pixels ever change). In every frame each region shows the background
or one transparent picture (the pixels that differ from the background)
at an offset; pictures are shared by all regions and frames.

Writes assets/mission/prelude-<screen>.png (background), and
assets/mission/prelude.json: per screen the palette (16 RGB, index 0
black), the colour of index 15 over time as runs [rgb, frames] (the
mansion windows' fire cycle; empty for the first screen), the regions (x, y, w, h) and for each region its runs
[picture, dx, dy, frames] (picture -1: background); the pictures go to
assets/mission/prelude-pictures.png (with index 0 transparent) and their
(x, y, w, h) in the atlas.
"""
import glob, hashlib, json, sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

OUT = Path('assets/mission')
TOP = 6                      # rows 6..217 of the arcade screen
# (name, capture, first captured frame, first, last, dilation)
# 'ending' is the mansion after the guardian falls (make
# capture-mission-ending: frames 8000..9400, the boss taken down with
# MISSION_BOSS_HITS=1): daylight palette, soldiers and fireworks.
# 'intro' is the cartridge's player-versus-CPU introduction (src/demo_b1.asm,
# make capture-intro-full: frames 370..810 after a coin at 300 and start at
# 360), rows 2..213 (the arcade uses rows 1..215): from frame 491, with both
# portraits in place, the two small runners and the typed names. Before
# that (377..490) NICK's portrait only slides into place; src/demo_b1.asm
# draws it from this screen's background (intro_slide).
SCREENS = (('attention', 'build/mission/prelude-mame', 3600, 3669, 4224, 1),
           ('mansion', 'build/mission/prelude-mame', 3600, 4247, 4619, 3),
           ('ending', 'build/mission/ending-mame-early', 8000, 8866, 9331, 1),
           ('intro', 'build/mame-intro-full', 370, 491, 793, 1))
SCREEN_TOP = {'intro': 2}
BLACK_BASE = ('attention',)             # no colour cycle; the base is black
NO_CYCLE = ('intro',)                   # base = first frame, no colour cycle

_files = {}
def frame(capture, first, n, top=TOP):
    if capture not in _files:
        _files[capture] = sorted(glob.glob(str(Path(capture) / 'combatsc' / '*.png')))
    return np.asarray(Image.open(_files[capture][n - first]).convert('RGB'))[top:top + 212].astype(float)

def palette(frames, k=15):
    """Black plus k colours: k-means over every colour, weighted by the
    square root of its use so that small details keep their colours."""
    X = np.concatenate([f.reshape(-1, 3) for f in frames[::2]])
    u, c = np.unique(X, axis=0, return_counts=True)
    if len(u) <= 16:
        cols = [tuple(v) for v in u if tuple(v) != (0, 0, 0)]
        return np.array([(0, 0, 0)] + cols + [(0, 0, 0)] * (k - len(cols)), float)
    w = np.sqrt(c)
    rng = np.random.default_rng(0)
    C = u[rng.choice(len(u), k, replace=False)]
    for _ in range(40):
        allc = np.vstack([[0, 0, 0], C])
        lab = ((u[:, None] - allc[None]) ** 2).sum(2).argmin(1)
        for j in range(k):
            m = lab == j + 1
            if m.any():
                C[j] = (u[m] * w[m, None]).sum(0) / w[m].sum()
    return np.vstack([[0, 0, 0], C])

def quantize(f, P):
    return ((f.reshape(-1, 1, 3) - P[None]) ** 2).sum(2).argmin(1).reshape(f.shape[:2]).astype(np.uint8)

pictures, picture_index, result = [], {}, {}
for name, capture, first, a, b, dilation in SCREENS:
    raw = [frame(capture, first, n, SCREEN_TOP.get(name, TOP)) for n in range(a, b + 1)]
    cycle = []
    if name in BLACK_BASE:
        P = palette(raw)
        Q = [quantize(f, P) for f in raw]
        base = np.zeros_like(Q[0])
        cycled = []
    else:
        # The windows' fire is a colour cycle in the arcade: pixels that
        # only change by following one colour mapping get index 15, whose
        # colour the ROM rewrites; the frames are then normalised.
        P = np.vstack([palette(raw, 14), [[0, 0, 0]]])
        Q = [quantize(f, P) for f in raw]
        base = Q[0].copy()
        if name in NO_CYCLE:
            P = palette(raw)
            Q = [quantize(f, P) for f in raw]
            base = Q[0].copy()
            cycled = []
        maps = []
        for q in (Q if name not in NO_CYCLE else []):
            M = list(range(16))
            for i in range(15):
                m = base == i
                if m.sum() >= 50:
                    v, c = np.unique(q[m], return_counts=True)
                    M[i] = int(v[c.argmax()])
            maps.append(M)
        if name not in NO_CYCLE:
            cycled = [i for i in range(15) if any(M[i] != i for M in maps)]
            assert len(cycled) <= 1, cycled
        ci = cycled[0] if cycled else None
    if cycled:
        hits = np.zeros(base.shape, int)
        for q, M in zip(Q, maps):
            if M[ci] != ci:
                hits += (base == ci) & (q == M[ci])
        cyc_frames = sum(1 for M in maps if M[ci] != ci)
        mask = (base == ci) & (hits * 2 > cyc_frames)
        base[mask] = 15
        P[15] = P[ci]
        for q, M in zip(Q, maps):
            colour = P[M[ci]]
            q[mask & (q == M[ci])] = 15
            if cycle and cycle[-1][0] == list(map(int, colour)) and cycle[-1][1] < 255:
                cycle[-1][1] += 1
            else:
                cycle.append([list(map(int, colour)), 1])
    changed = np.zeros(base.shape, bool)
    for q in Q:
        changed |= q != base
    lab, _ = ndimage.label(ndimage.binary_dilation(changed, iterations=dilation))
    # Every frame state of every region; the states with most changed
    # pixels first, so that a later, smaller one can reuse their picture
    # when drawing it somewhere in the region gives exactly the same frame.
    boxes = []
    for sl in ndimage.find_objects(lab):
        x, y = sl[1].start, sl[0].start
        boxes.append((x, y, sl[1].stop - x, sl[0].stop - y))
    states = [[None] * len(Q) for _ in boxes]
    items = []
    for k, (x, y, w, h) in enumerate(boxes):
        bg = base[y:y + h, x:x + w]
        for t, q in enumerate(Q):
            r = q[y:y + h, x:x + w]
            d = r != bg
            if not d.any():
                states[k][t] = (-1, 0, 0)
            else:
                items.append((-int(d.sum()), k, t))
    items.sort()
    own = []                            # this screen's pictures
    for _, k, t in items:
        x, y, w, h = boxes[k]
        r, bg = Q[t][y:y + h, x:x + w], base[y:y + h, x:x + w]
        d = r != bg
        ys, xs = np.nonzero(d)
        y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
        pic = np.where(d, r, 0)[y0:y1 + 1, x0:x1 + 1]
        # Opaque pixels of colour 0 (black) would be transparent.
        pic = np.where(d[y0:y1 + 1, x0:x1 + 1] & (pic == 0), 255, pic)
        key = name + hashlib.md5(pic.tobytes() + str(pic.shape).encode()).hexdigest()
        if key in picture_index:
            states[k][t] = (picture_index[key], int(x0), int(y0))
            continue
        found = None
        for i in own:
            P_ = pictures[i][0]
            ph, pw = P_.shape
            if ph < y1 - y0 + 1 or pw < x1 - x0 + 1 or ph > h or pw > w:
                continue
            opaque = P_ != 0
            colour = np.where(P_ == 255, 0, P_)
            for oy in range(max(0, y1 - ph + 1), min(y0, h - ph) + 1):
                for ox in range(max(0, x1 - pw + 1), min(x0, w - pw) + 1):
                    rr = r[oy:oy + ph, ox:ox + pw]
                    if not (colour == rr)[opaque].all():
                        continue
                    inside = np.zeros_like(d)
                    inside[oy:oy + ph, ox:ox + pw] = opaque
                    if (d & ~inside).any():
                        continue
                    found = (i, ox, oy)
                    break
                if found:
                    break
            if found:
                break
        if found:
            states[k][t] = found
            continue
        picture_index[key] = len(pictures)
        own.append(len(pictures))
        pictures.append((pic, name))
        states[k][t] = (picture_index[key], int(x0), int(y0))
    regions = []
    for k, (x, y, w, h) in enumerate(boxes):
        runs = []
        for state in states[k]:
            if runs and tuple(runs[-1][:3]) == state and runs[-1][3] < 255:
                runs[-1][3] += 1
            else:
                runs.append([*state, 1])
        regions.append({'box': [int(x), int(y), int(w), int(h)], 'runs': runs})
    Image.fromarray(P[base].astype(np.uint8)).save(OUT / f'prelude-{name}.png')
    result[name] = {'palette': [list(map(int, c)) for c in P], 'frames': b - a + 1, 'regions': regions,
                    'cycle': cycle}

# Pictures packed in rows of 256 pixels, tallest first; black (255) stays
# in the RGB atlas through each screen's palette entry 0.
order = sorted(range(len(pictures)), key=lambda i: -pictures[i][0].shape[0])
atlas_boxes, x, y, row_h = [None] * len(pictures), 0, 0, 0
for i in order:
    h, w = pictures[i][0].shape
    if x + w > 256:
        x, y, row_h = 0, y + row_h, 0
    atlas_boxes[i] = [x, y, w, h]
    x += w + (w & 1)
    row_h = max(row_h, h)
height = y + row_h
atlas = np.zeros((height, 256, 4), np.uint8)
for i, (pic, name) in enumerate(pictures):
    P = np.array(result[name]['palette'])
    x, y, w, h = atlas_boxes[i]
    rgb = np.where((pic == 255)[..., None], 0, P[np.minimum(pic, 15)])
    atlas[y:y + h, x:x + w, :3] = rgb
    atlas[y:y + h, x:x + w, 3] = np.where(pic == 0, 0, 255)
Image.fromarray(atlas, 'RGBA').save(OUT / 'prelude-pictures.png')
result['pictures'] = [{'screen': name, 'box': box} for (pic, name), box in zip(pictures, atlas_boxes)]
json.dump(result, open(OUT / 'prelude.json', 'w'))
for name, *_ in SCREENS:
    s = result[name]
    print(f"{name}: {len(s['regions'])} regions, {sum(len(r['runs']) for r in s['regions'])} runs, "
          f"{sum(1 for p in pictures if p[1] == name)} pictures")
print(f'atlas {height} rows')
