#!/usr/bin/env python3
"""Draw arbitrary K007121 sprite codes from the arcade graphics ROM.

Poses that the captures never show (the player's arm raised at the iron man
goal, wading) are built from the same codes and bank bits that the CPU's
captured poses use. entry() mirrors tools/arcade_sprites.py.
"""
from pathlib import Path
from PIL import Image
import arcade_sprites


def entry(num, bank, attr, colour, palette, group=4, circuit=1):
    gfx, prom = arcade_sprites._load(circuit)
    typ = attr & 14
    w, h = {6: (1, 1), 4: (1, 2), 2: (2, 1), 0: (2, 2), 8: (4, 4)}[typ]
    n = ((num + ((bank & 3) << 8) + ((attr & 0xc0) << 4)) << 2) + ((bank >> 2) & 3)
    n &= ~(2 if typ == 4 else 1 if typ == 2 else 3 if typ in (0, 8) else 0)
    image = Image.new('RGBA', (w * 8, h * 8))
    for ty in range(h):
        for tx in range(w):
            ex = w - 1 - tx if attr & 16 else tx
            tile = n + [0, 1, 4, 5][ex] + [0, 2, 8, 10][ty]
            for y in range(8):
                for x in range(8):
                    px = 7 - x if attr & 16 else x
                    byte = gfx[tile * 32 + y * 4 + px // 2]
                    pen = byte >> 4 if px % 2 == 0 else byte & 15
                    lookup = prom[colour * 16 + pen] & 15
                    if not lookup:
                        continue
                    idx = group * 16 + lookup
                    c = palette[idx * 2] | palette[idx * 2 + 1] << 8
                    image.putpixel((tx * 8 + x, ty * 8 + y),
                                   tuple((((c >> s) & 31) << 3) | (((c >> s) & 31) >> 2) for s in (0, 5, 10)) + (255,))
    return image


def front_pose(top, legs, colour, palette):
    """32x32 upper body (bank 3) with 16x16 legs below, as at the goal."""
    image = Image.new('RGBA', (32, 48))
    upper = entry(top, 3, 0x98, colour, palette)
    image.paste(upper, (0, 0), upper)
    if legs is not None:
        lower = entry(legs, 3, 0x90, colour, palette)
        image.paste(lower, (8, 32), lower)
    return image.crop(image.getbbox())
