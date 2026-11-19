#!/usr/bin/env python3
"""Fit the arcade iron man course (tools/stitch_ironman.py) to the ROM's
course geometry and produce its VRAM image and collision tables.

World coordinates: y=0 at the bottom (start), growing towards the goal; the
ROM camera of a runner at progress P shows world rows P..P+183 and the
runner's feet are at world P+48 (screen row 135). The ROM switches to swimming at P=2048,
leaves the water at P=3072 and finishes at P=3328, so the arcade course is
shortened by removing featureless rows (multiples of 8, the tile size):

  * start line at world 46, near shore at 2096 (160 land rows removed),
  * far shore at 3119 (152 rows of plain water removed),
  * finish line at 3376 (176 rows of the final straight removed).

Outputs in build/ironman/:
  world.png          120x4096, top row = world 4095 (for review)
  land.bin           256x2048 4bpp: x 0..119 = world 0..2047, x 128..247 =
                     world 2048..4095, each half with world y growing upwards
  collision.bin      512 rows x 16 cells: 0 free, 1 puddle, 2 mine, 3 rock,
                     4 vegetation (blocks, as in the arcade)
  surfaces.bin       256 rows x 16 cells (land): 1 bridge water, 2 bridge deck
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image

SRC = Path('build/ironman')
idx = np.load(SRC / 'course-index.npy')[::-1]       # row 0 = arcade start
# Arcade columns 0-4 of the CPU lane (x=130..134) are always covered by a
# sprite next to the divider, so they have no data: mirror columns 5-9 there
# instead of leaving a plain sand stripe along the lane's left edge.
for x in range(5):
    idx[:, x] = idx[:, 9 - x]
WIDTH = idx.shape[1]                                 # 118 arcade pixels

# Arcade landmarks (rows from the first captured line, i.e. arcade progress).
START_LINE, NEAR_SHORE, FAR_SHORE, FINISH_LINE = 52, 2262, 3437, 3870
CUTS = [(124, 64), (850, 48), (1980, 48),            # plain land
        (2750, 152),                                 # plain water
        (3460, 176)]                                 # final straight
WORLD_START_LINE = 46

keep = np.ones(len(idx), bool)
for start, length in CUTS:
    assert start % 2 == 0
    keep[start:start + length] = False
rows = idx[keep][START_LINE - WORLD_START_LINE:]

def world_of(arcade_row):
    return int(keep[:arcade_row].sum()) - (START_LINE - WORLD_START_LINE)

assert world_of(START_LINE) == WORLD_START_LINE
landmarks = {'near_shore': world_of(NEAR_SHORE), 'far_shore': world_of(FAR_SHORE),
             'finish_line': world_of(FINISH_LINE)}
assert abs(landmarks['near_shore'] - 2096) <= 2, landmarks
assert abs(landmarks['far_shore'] - 3119) <= 2, landmarks
assert abs(landmarks['finish_line'] - 3376) <= 2, landmarks

# Unknown pixels (always covered by a sprite) take the nearest known pixel
# 8 or 16 rows away, keeping the 8x8 tile texture.
world = np.full((4096, 120), 255, np.int16)
world[:len(rows), 1:1 + WIDTH] = rows[:4096]
world[:, 0] = world[:, 1]; world[:, 119] = world[:, 118]
for y in range(4096):
    for x in np.nonzero(world[y] == 255)[0]:
        for d in (8, -8, 16, -16, 24, -24, 32, -32, 64, -64):
            if 0 <= y + d < 4096 and world[y + d, x] != 255:
                world[y, x] = world[y + d, x]
                break
# Beyond the captured goal area the sand continues.
last = len(rows) - 1
for y in range(last + 1, 4096):
    world[y] = world[last - 15 + (y - last - 1) % 16]

# Bridges: the stitched captures left seams (logs 8 to 10 pixels wide,
# sections shifted by a pixel), the second bridge's bottom crossbar out of
# line and the third's top end broken (with sprite pixels on its left edge).
# All three are drawn from one regular bridge built from the first: six
# logs of 8 pixels between dark lines, the same rounded ends, the same two
# crossbars. Rows 514..618, x 18..72 for the first bridge.
B1_X = 18
def log_tile(y, c0):
    """Row y of one log of the first bridge (dark line + 8 pixels) six times."""
    s = world[y, B1_X + c0:B1_X + c0 + 9]
    return np.concatenate([s] * 6 + [s[:1]])
log_row = log_tile(521, 0)
canon = {}
for y in range(514, 521): canon[y] = log_tile(y, 18)          # bottom ends
for y in range(521, 528): canon[y] = log_row
for y in range(528, 531): canon[y] = log_tile(y, 9)           # under the crossbar
for y in range(531, 537): canon[y] = world[y, B1_X:B1_X + 55].copy()   # crossbar
for y in range(537, 603): canon[y] = log_row
for y in range(603, 606): canon[y] = log_tile(y - 75, 9)
for y in range(606, 613): canon[y] = world[min(y - 75, 536), B1_X:B1_X + 55].copy()
for y in range(613, 617): canon[y] = log_row
for y in range(617, 619): canon[y] = log_tile(y, 27)          # top ends
b1 = world[514:622, B1_X:B1_X + 55].copy()                     # 3 rows of sand above
for y, row in canon.items():
    b1[y - 514] = row
world[514:622, B1_X:B1_X + 55] = b1
world[976:976 + 108, 26:26 + 55] = b1                          # second: x 26..80
for y in range(976, 976 + 108):
    world[y, 23:26] = world[y, 22]       # its misplaced crossbar overhang
world[1743:1743 + 108, 0:51] = b1[:, 4:55]                     # third, at the lane's left edge
# The bank right of the third bridge's top: the first bridge's rocky bank,
# aligned on the water's edge (row 598 there, 1830 here).
bank = world[588:619, 73:120].copy()
world[1820:1851, 51:98] = bank
world[1820:1851, 98:120] = bank[:, 25:47]

# Mines are arcade sprites (circuit 0, code 53), so the background
# reconstruction lost them; draw them back at the positions seen by the CPU's
# camera (arcade row of the sprite centre, sprite x in the CPU lane).
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_sprites
MINES = [(994, 162), (2159, 225)]
mine_frame = sorted(Path('build/mame-ironman').glob('frame-*'))[200]
mine_sprite = arcade_sprites.render(mine_frame, 0, 0, (162, 58, 163, 59), 0, {53}).crop((162, 58, 178, 74))
mine_cells = []
for arcade_row, sx in MINES:
    centre = world_of(arcade_row)
    left = sx - 130 + 1
    for k in range(16):
        for j in range(16):
            r, g, b, a = mine_sprite.getpixel((j, k))
            if a:   # -1 dark body, -2 highlight
                world[centre + 8 - k, left + j] = -2 if r + g + b > 200 else -1
    mine_cells.append((centre // 8, (left + 8) // 8))

# Arcade palette index -> ROM pen (roles kept from build_step3_visual.py).
PEN = {19: 1, 20: 1, 21: 2, 22: 6, 25: 3, 24: 7, 23: 5,
       26: 9, 27: 10, 28: 15, 30: 14, 29: 11, 31: 12, 17: 8, 15: 3,
       5: 6, 6: 2, 2: 7, 3: 5, 4: 11}
# Mine pixels were stored as -1 (dark) and -2 (highlight).
pens = np.vectorize(lambda v: 12 if v == -1 else 14 if v == -2 else PEN.get(int(v), 1))(world).astype(np.uint8)
# The river. Between the shores the arcade swaps its palette: entries 23, 24,
# 25 (the vegetation's greens on land) and 28 hold four blues it rotates,
# entry 28 one step behind 25, 25 behind 24, 24 behind 23. The ROM has two
# rotating pens (src/step3_visual.asm water_cycle): 15 for 28 and 25, 10 two
# steps ahead for 24 and 23. Entry 27 (light water, puddle edges) takes
# pen 9 everywhere, so pen 10 is free for the river.
pens[world == 27] = 9
river = slice(world_of(NEAR_SHORE) - 4, world_of(FAR_SHORE) + 5)
part = world[river]
water = pens[river]
water[np.isin(part, (25, 28))] = 15
water[np.isin(part, (23, 24))] = 10
pens[river] = water

# Things of the arcade frames the stitch kept that the arcade's course does
# not show (seen against the arcade video, ironManArcade.webm): green marks
# below the start line, two black stakes by the left edge, a dark line under
# the cliff by the third bridge, two bars and a dark shape in the river.
# (world rows, columns, ground) boxes; each pixel that is not of that ground
# (sand or water) takes the nearest pixel of it in its row, so the texture
# goes on.
SAND, WATER = (1, 2, 6), (9, 10, 15)
STRAYS = [((0, 27), (18, 35), SAND), ((912, 926), (2, 10), SAND),
          ((1942, 1954), (2, 10), SAND), ((1811, 1823), (49, 77), WATER),
          ((2476, 2493), (100, 118), WATER), ((2550, 2568), (0, 16), WATER)]
for (y0, y1), (x0, x1), ground in STRAYS:
    for y in range(y0, y1):
        row = pens[y]
        good = [x for x in range(120) if row[x] in ground and not (x0 <= x < x1)]
        for x in range(x0, x1):
            if row[x] not in ground and good:
                row[x] = row[min(good, key=lambda g: abs(g - x))]

# VRAM image: two halves of 2048 lines, world y growing upwards.
vram = np.zeros((2048, 256), np.uint8)
vram[:, 0:120] = pens[0:2048][::-1]
vram[:, 128:248] = pens[2048:4096][::-1]
packed = (vram[:, 0::2] << 4) | vram[:, 1::2]
(SRC / 'land.bin').write_bytes(packed.tobytes())

colours = json.loads((SRC / 'palette.json').read_text()) if (SRC / 'palette.json').exists() else None
preview_pal = [(0, 0, 0), (214, 173, 123), (189, 156, 123), (49, 90, 57), (232, 128, 0),
               (115, 148, 115), (189, 140, 115), (90, 115, 99), (239, 239, 239),
               (0, 148, 156), (0, 165, 173), (148, 115, 90), (49, 49, 49), (240, 16, 0),
               (115, 107, 99), (0, 140, 181)]
Image.fromarray(np.array(preview_pal, np.uint8)[pens[::-1]]).save(SRC / 'world.png')

# Collision cells (8x8) from the arcade pixels: puddles are water inside the
# land sections; rocks are the rock pixels (stone grey and outline) in a cell.
WATER = {26, 27, 28}
WOOD = {29}
collision = np.zeros((512, 16), np.uint8)
surfaces = np.zeros((256, 16), np.uint8)
candidate = np.zeros((512, 16), bool)
for row in range(512):
    for cell in range(15):
        block = world[row * 8:row * 8 + 8, cell * 8:cell * 8 + 8]
        water = np.isin(block, list(WATER)).mean()
        stone = (block == 30).mean()         # rock grey; dark 31 also outlines bushes
        wood = np.isin(block, list(WOOD)).mean()
        y = row * 8
        on_land = y < landmarks['near_shore'] - 8 or y >= landmarks['far_shore'] + 8
        # Rocks and bridge planks both mix grey and brown.
        bush = np.isin(block, [23, 24, 25]).mean()
        if wood + stone >= 0.35:
            candidate[row, cell] = True
        elif on_land and water >= 0.5:
            collision[row, cell] = 1
        elif on_land and bush >= 0.5:
            collision[row, cell] = 4        # vegetation stops the runner
# A bridge deck is a large grey/brown area (at least 5x5 cells); anything
# smaller is a rock.
seen = np.zeros_like(candidate)
for r0 in range(512):
    for c0 in range(15):
        if not candidate[r0, c0] or seen[r0, c0]:
            continue
        stack, part = [(r0, c0)], []
        seen[r0, c0] = True
        while stack:
            r, c = stack.pop(); part.append((r, c))
            for nr, nc in ((r + 1, c), (r - 1, c), (r, c + 1), (r, c - 1)):
                if 0 <= nr < 512 and 0 <= nc < 15 and candidate[nr, nc] and not seen[nr, nc]:
                    seen[nr, nc] = True; stack.append((nr, nc))
        rs = [r for r, _ in part]; cs = [c for _, c in part]
        bridge = max(rs) - min(rs) >= 4 and max(cs) - min(cs) >= 4 and max(rs) < 256
        for r, c in part:
            if bridge:
                surfaces[r, c] = 2
            else:
                collision[r, c] = 3
# Water next to a bridge deck is wading water, not a puddle that trips.
for row in range(256):
    if surfaces[max(0, row - 6):row + 7].any():
        for cell in range(15):
            if collision[row, cell] == 1:
                collision[row, cell] = 0
                surfaces[row, cell] = surfaces[row, cell] or 1
# Posts and ropes at the edges of a bridge (next to its deck or its wading
# water) are part of it, not rocks.
for r in range(256):
    for c in range(15):
        if collision[r, c] == 3 and (surfaces[max(0, r - 2):r + 3, max(0, c - 2):c + 3] > 0).any():
            collision[r, c] = 0
for row, cell in mine_cells:
    collision[row, cell] = 2
# The ROM looks cells up at progress P (row P/8) while the runner's feet are
# at world P+48: store each table six rows ahead.
collision = np.vstack([collision[6:], np.zeros((6, 16), np.uint8)])
surfaces = np.vstack([surfaces[6:], np.zeros((6, 16), np.uint8)])
(SRC / 'collision.bin').write_bytes(collision.tobytes())
(SRC / 'surfaces.bin').write_bytes(surfaces.tobytes())
(SRC / 'landmarks.json').write_text(json.dumps(landmarks, indent=1))
print('landmarks', landmarks, 'rock cells', int((collision == 3).sum()),
      'puddle cells', int((collision == 1).sum()), 'deck cells', int((surfaces == 2).sum()))
