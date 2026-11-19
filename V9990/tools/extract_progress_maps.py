#!/usr/bin/env python3
"""The two event maps from MAME, whole, in the ROM's 212 lines (18-nov).

The arcade draws them in 224 lines: seven bands of 32 (a gold square and a
picture box of 31 lines and a separator line, the texts at the band's lines
0 and 16). The ROM shows 212, so 12 lines go, and none of what is drawn is
cut: bands 1..6 lose 2 lines each (band 0, the top one, stays whole), so
every band after the first is 30 lines:

- the text column (x >= 80): two empty lines of the band (its gaps, near
  lines 12 and 28), so the letters keep all their rows;
- the squares and pictures (x < 80): the two lines of the band's lines
  1..29 most like the line above them (the gold squares are flat there, and
  the pictures lose two lines of their most uniform background).

Band b starts at line 0 (b = 0) or 32 + 30 (b - 1); its square is 31 lines
(b = 0) or 29.

- assets/progression/map.png, after Steps 1..6 and the penalty (STEP 7 on
  top, OBSTACLE COURSE at the bottom): the square of step n is band 7 - n,
  y = 32 + 30 (6 - n), 29 lines. Source: MAME, build/mame-map frame 0029
  (archived in ../build/capture-archives/20261116T172820701380Z/mame-map).
- assets/step7-ending/map.png, after the instructor (??? and
  CONGRATULATIONS on top): the blinking squares of steps 7..3 are bands
  2..6, y = 62, 92, 122, 152 and 182. Source: MAME, a frame with those
  squares white: the ceremony capture (tools/mame_step7_ceremony_capture.lua)
  with snapshots at frames 1050..1950 every 5 frames; the map is snapshots
  0058..0082.

usage: extract_progress_maps.py MAP_FRAME ENDING_FRAME"""
import sys
import numpy as np
from PIL import Image

TEXT_X = 80                       # the text column (the pictures end at 71)
BAND = 32


def removed_rows(a, y0, left):
    """Two lines of band y0 to drop, in the left or the text column."""
    region = a[:, :TEXT_X] if left else a[:, TEXT_X:]
    if left:
        cost = [(np.abs(region[y0 + k] - region[y0 + k - 1]).sum(), k) for k in range(1, 30)]
        first = min(cost)[1]
        second = min(c for c in cost if abs(c[1] - first) > 1)[1]
        return sorted((first, second))
    blank = [k for k in range(BAND) if (region[y0 + k] == region[y0 + k, 0]).all()]
    picks = [min(blank, key=lambda k: abs(k - want)) for want in (12, 28)]
    if picks[0] == picks[1]:
        picks[1] = min((k for k in blank if k != picks[0]), key=lambda k: abs(k - 28))
    return sorted(picks)


def squeeze(path, check=None):
    arcade = Image.open(path).convert('RGB')
    assert arcade.size == (256, 224)
    if check:
        check(arcade)
    a = np.asarray(arcade).astype(int)
    left_rows, text_rows = list(range(BAND)), list(range(BAND))
    for b in range(1, 7):
        y0 = b * BAND
        drop_left, drop_text = removed_rows(a, y0, True), removed_rows(a, y0, False)
        left_rows += [y0 + k for k in range(BAND) if k not in drop_left]
        text_rows += [y0 + k for k in range(BAND) if k not in drop_text]
    assert len(left_rows) == len(text_rows) == 212
    out = np.concatenate([a[left_rows][:, :TEXT_X], a[text_rows][:, TEXT_X:]], axis=1)
    return Image.fromarray(out.astype(np.uint8), 'RGB')


def white_squares(arcade):
    assert arcade.getpixel((20, 70)) == (239, 239, 239)


if __name__ == '__main__':
    squeeze(sys.argv[1]).save('assets/progression/map.png')
    squeeze(sys.argv[2], white_squares).save('assets/step7-ending/map.png')
    print('event maps: assets/progression/map.png, assets/step7-ending/map.png')
