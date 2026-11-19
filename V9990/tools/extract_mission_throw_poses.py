#!/usr/bin/env python3
"""Rebuild blue knife-throw poses from arcade sprite tiles and a MAME palette.

Run from V9990 after capture-mission-expanded. Upper-body tile numbers come
from the arcade graphics; common standing legs are tile 4. The combinations
are approximate and do not establish the original animation state machine.
"""
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

palette = Path('build/mission/course-beyond-probe/frame-5532/palette.bin').read_bytes()
with ZipFile('../ARCADE/original/combatsc.zip') as rom:
    even, odd, prom = (rom.read(n) for n in ('611g07.rom', '611g08.rom', '611g06.h14'))
gfx = bytearray(len(even) * 2)
gfx[::2], gfx[1::2] = even, odd
out = Path('assets/mission')
out.mkdir(parents=True, exist_ok=True)
for upper in (40, 44, 48):
    image = Image.new('RGBA', (32, 64))
    bank, attr = 2, 216
    for offset_y, number in ((0, upper), (32, 4)):
        base = (((number + ((bank & 3) << 8) + ((attr & 0xc0) << 4)) << 2)
                + ((bank >> 2) & 3)) & ~3
        for ty in range(4):
            for tx in range(4):
                ex = 3-tx if attr & 16 else tx
                ey = 3-ty if attr & 32 else ty
                tile = base + (0, 1, 4, 5)[ex] + (0, 2, 8, 10)[ey]
                for y in range(8):
                    for x in range(8):
                        px = 7-x if attr & 16 else x
                        py = 7-y if attr & 32 else y
                        b = gfx[tile*32 + py*4 + px//2]
                        pen = b >> 4 if px % 2 == 0 else b & 15
                        index = prom[(bank >> 4)*16 + pen] & 15
                        if not index:
                            continue
                        colour = palette[index*2] | palette[index*2+1] << 8
                        rgb = tuple((((colour >> shift) & 31) << 3) |
                                    (((colour >> shift) & 31) >> 2)
                                    for shift in (0, 5, 10))
                        image.putpixel((tx*8+x, offset_y+ty*8+y), (*rgb, 255))
    if upper == 48:
        # The extended hand is a separate arcade sprite, outside the captured
        # 32-pixel upper-body tile. Add a small hand at the arm's cut edge.
        extended = Image.new('RGBA', (36, 64))
        extended.alpha_composite(image, (4, 0))
        for x, y in ((1, 21), (2, 21), (3, 21), (1, 22), (2, 22),
                     (3, 22), (2, 23), (3, 23), (3, 24)):
            extended.putpixel((x, y), (222, 148, 115, 255))
        image = extended
    image.save(out / f'enemy-throw-{upper}.png')
