#!/usr/bin/env python3
"""Text screens of the arcade ending, from the per-frame MAME capture of
frames 9000..12850 (make capture-mission-ending; the boss falls earlier).

Writes assets/mission/ending-font.png: the 8x8 glyphs of the arcade text
font, in the order of GLYPHS, glyph pixels white (239,239,239) and their
shadow grey (33,33,33); and assets/mission/ending.json: the RGB colours of
the RANKING title colour cycle (one per 4 frames, one period) and the
colours of the rank screen blink.

The glyphs come from known text at known cells (8x8 grid) of three frames:
the officer rank screen, CONGRATULATIONS and the RANKING table.
"""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image

CAPTURE = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/mission/ending-mame') / 'combatsc'
FIRST = 9000
OUT = Path('assets/mission')
GLYPHS = 'ACDEFGHIKLMNOPRSTUVY0123456789().!>BJQWXZ?#'   # '>' the arrow after "1P", '#' END
SHADOW = (33, 33, 33)

# (frame, cell row, first cell column, text); spaces skip a cell.
SOURCES = [
    (9500, 0, 12, 'YOUR  TITLE'),
    (9500, 2, 7, 'OVER'),
    (9500, 3, 11, '370000PTS'),
    (9500, 6, 11, '340000PTS LIEUTENANT'),
    (9500, 5, 21, 'FIRST'),
    (9500, 8, 1, '1P>'),
    (9500, 8, 21, 'SECOND'),
    (9500, 11, 21, 'MASTER'),
    (9500, 12, 21, 'SERGEANT'),
    (9500, 17, 21, 'CORPORAL'),
    (9500, 20, 21, 'PRIVATE'),
    (9500, 23, 21, 'ROOKIE'),
    (9500, 26, 5, 'P1 (NICK)'),
    (10300, 10, 8, 'CONGRATULATIONS!'),
    (10300, 13, 5, 'THANK YOU FOR PLAYING'),
    (10700, 7, 10, '304500'),
    (10700, 7, 25, 'S.LT.'),
    (10700, 9, 3, '2ND'),
    (10700, 11, 10, '214800'),
    (10700, 15, 10, '184100'),
    (10700, 17, 10, '160760'),
    (10700, 19, 11, '88500'),
    (10700, 21, 11, '58100'),
    (10700, 23, 3, '9TH'),
    (10700, 23, 11, '44600'),
    (10700, 25, 11, '31330'),
]


NAME = Path('build/mission/ending-mame-name/combatsc')
NAME_FIRST = 10400
# Initials in the RANKING (NAME_ENTRY=1 NAME_DIR='P1 Right' capture, frames
# 10400..11000): right every 12 frames from 10470 shows B, C, ..., Z, space,
# '.', at cell (19, 7); button 1 at 10800, then right gives '!', '?' and END
# at cell (20, 7).
NAME_SOURCES = [(10477 + 12 * 'BCDEFGHIJKLMNOPQRSTUVWXYZ'.index(c), 7, 19, c) for c in 'BJQWXZ']
NAME_SOURCES += [(10849, 7, 20, '?'), (10861, 7, 20, '#')]   # '!' as in CONGRATULATIONS!


def frame(n):
    if n < 0:
        return np.asarray(Image.open(NAME / f'{-n - NAME_FIRST:04d}.png').convert('RGB')).astype(int)
    return np.asarray(Image.open(CAPTURE / f'{n - FIRST:04d}.png').convert('RGB')).astype(int)


def glyph(a, row, col):
    cell = a[row * 8:row * 8 + 8, col * 8:col * 8 + 8]
    shadow = (cell == SHADOW).all(2)
    fg = (cell.sum(2) > 0) & ~shadow
    return fg, shadow


found = {}
for n, row, col, text in SOURCES + [(-n, r, c, t) for n, r, c, t in NAME_SOURCES]:
    a = frame(n)
    for k, ch in enumerate(text):
        if ch == ' ':
            continue
        fg, sh = glyph(a, row, col + k)
        assert fg.any(), (n, row, col + k, ch)
        if ch in found:
            assert (found[ch][0] == fg).all() and (found[ch][1] == sh).all(), (ch, n, row, col + k)
        found[ch] = (fg, sh)
missing = [c for c in GLYPHS if c not in found]
assert not missing, missing

font = np.zeros((8, 8 * len(GLYPHS), 3), np.uint8)
for i, ch in enumerate(GLYPHS):
    fg, sh = found[ch]
    font[:, i * 8:i * 8 + 8][sh] = SHADOW
    font[:, i * 8:i * 8 + 8][fg] = (239, 239, 239)
Image.fromarray(font).save(OUT / 'ending-font.png')


def text_colour(a, row):
    band = a[row * 8:row * 8 + 8].reshape(-1, 3)
    cols = {tuple(int(v) for v in c) for c in band} - {(0, 0, 0), SHADOW}
    assert len(cols) == 1, cols
    return list(cols.pop())


# RANKING title (cell row 3): one colour per 4 frames, period 112 frames.
cycle = [text_colour(frame(n), 3) for n in range(10459, 10571, 4)]
assert text_colour(frame(10571), 3) == cycle[0]
blink = [text_colour(frame(9340), 9), text_colour(frame(9350), 9)]
json.dump({'glyphs': GLYPHS, 'title_cycle': cycle, 'blink': blink}, open(OUT / 'ending.json', 'w'))
print(len(GLYPHS), 'glyphs; cycle', len(cycle), 'colours:', sorted({tuple(c) for c in cycle}))
