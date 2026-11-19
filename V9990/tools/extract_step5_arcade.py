#!/usr/bin/env python3
"""Arcade graphics of the arm wrestling (Step 5) from MAME.

Sources: tools/mame_step5_capture.lua (build/mame-step5, clock digits) and
tools/mame_step5_mash.lua replays with no presses (build/mame-step5-m0) and
with the fastest presses (build/mame-step5-m2), one snapshot every 2 frames.
The ROM uses the arcade screen coordinates directly: rows 0..211, with the
score line (rows 0..15) left black.

Outputs in assets/step5:
  arcade-front.png     front view without READY
  arcade-struggle.png  overhead, hands centred, without texts or digits
  arcade-finish.png    overhead, player has won, without texts or digits
  arcade-extra.png     256x172 RGBA strip stored at VRAM y 980..1151:
                       CPU advantage (0,0), player advantage (128,0) and
                       CPU win (0,86), opaque 128x86 patches; clock digits
                       0-9 (128,86) 8x13; READY (128,100), START (128,108),
                       STOP (128,116), PLAYER 1 WIN!! (128,124) and
                       CPU 2 WIN (128,132), transparent, 8 rows each.
"""
from pathlib import Path
import numpy as np
from PIL import Image

M0 = sorted(Path('build/mame-step5-m0/combatsc').glob('*.png'))
M2 = sorted(Path('build/mame-step5-m2/combatsc').glob('*.png'))
OUT = Path('assets/step5')
# Patch positions on screen (x, y) for 128x86 boxes; see doc/referencia-step5.md.
PATCHES = {'losing': (58, 71), 'winning': (53, 72), 'cpuwin': (54, 70)}
TABLE = (99, 74, 57)
TEXT_COLOURS = ((231, 231, 231), (255, 0, 0), (33, 49, 33))   # letters, their shadow


def frame(files, frame_number):
    return np.asarray(Image.open(files[frame_number // 2]).convert('RGB')).copy()


def clean(image, neutral):
    image = image[:212].copy()
    image[:16] = 0                                   # score line
    image[26:39, 120:136] = 0                        # clock seconds
    image[26:39, 144:152] = 0                        # clock tenths
    image[196:210, 30:230] = 0                       # power bars (ROM draws them)
    # STOP / START (rows 72-80) and READY (80-88) on the table: only their
    # pixels become table. The whole box from the centred pose cut the top
    # of the hands in the other poses (the victory's fists start at row 78).
    box = image[72:88, 104:144]
    text = np.zeros(box.shape[:2], bool)
    for colour in TEXT_COLOURS:
        text |= (box == colour).all(axis=2)
    box[text] = TABLE
    image[44:56] = 0                                 # winner text
    return image


def text(image, box, colour):
    x0, y0, x1, y1 = box
    crop = image[y0:y1, x0:x1]
    if colour == 'white':
        mask = crop.min(axis=2) > 200
    else:
        mask = (crop[:, :, 0] > 200) & (crop[:, :, 1] < 60) & (crop[:, :, 2] < 60)
    rgba = np.zeros(crop.shape[:2] + (4,), np.uint8)
    rgba[mask] = (248, 248, 240, 255) if colour == 'white' else (240, 8, 8, 255)
    return rgba


def digits():
    """Clock ones digit, in order of appearance from 0:32.0 downwards."""
    first = 12952
    seen = []
    for n in range(13300, 14080, 4):
        image = np.asarray(Image.open(f'build/mame-step5/combatsc/{(n - first) // 4:04d}.png').convert('RGB'))
        cell = image[26:39, 128:136]
        if cell.max() >= 100 and not any((cell == s).all() for s in seen):
            seen.append(cell.copy())
    assert len(seen) == 10, len(seen)
    glyphs = {}
    for value, cell in zip((2, 1, 0, 9, 8, 7, 6, 5, 4, 3), seen):
        rgba = np.zeros((13, 8, 4), np.uint8)
        rgba[cell.min(axis=2) > 200] = (248, 248, 240, 255)
        glyphs[value] = rgba
    return glyphs


if __name__ == '__main__':
    neutral = frame(M0, 460)                          # READY, hands centred
    neutral[80:88, 104:144] = frame(M0, 480)[80:88, 104:144]
    front = frame(M0, 320)[:212]; front[:16] = 0
    Image.fromarray(front).save(OUT / 'arcade-front.png')
    Image.fromarray(clean(neutral, neutral)).save(OUT / 'arcade-struggle.png')
    Image.fromarray(clean(frame(M2, 760), neutral)).save(OUT / 'arcade-finish.png')
    extra = np.zeros((172, 256, 4), np.uint8)
    sources = {'losing': frame(M0, 528), 'winning': frame(M2, 690), 'cpuwin': frame(M0, 660)}
    for (name, (x, y)), (ox, oy) in zip(PATCHES.items(), ((0, 0), (128, 0), (0, 86))):
        image = clean(sources[name], neutral)
        extra[oy:oy + 86, ox:ox + 128, :3] = image[y:y + 86, x:x + 128]
        extra[oy:oy + 86, ox:ox + 128, 3] = 255
    for value, glyph in digits().items():
        extra[86:99, 128 + value * 8:136 + value * 8] = glyph
    labels = [((104, 80, 144, 88), frame(M0, 460), 'white'),     # READY
              ((104, 72, 144, 80), frame(M0, 488), 'red'),       # START
              ((104, 72, 136, 80), frame(M0, 660), 'white'),     # STOP
              ((72, 48, 182, 56), frame(M2, 800), 'white'),      # PLAYER 1 WIN!!
              ((88, 48, 160, 56), frame(M0, 660), 'red')]        # CPU 2 WIN
    for k, (box, image, colour) in enumerate(labels):
        glyph = text(image, box, colour)
        extra[100 + k * 8:108 + k * 8, 128:128 + glyph.shape[1]] = glyph
    Image.fromarray(extra, 'RGBA').save(OUT / 'arcade-extra.png')
    print('step 5 arcade graphics in', OUT)
