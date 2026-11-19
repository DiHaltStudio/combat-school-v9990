#!/usr/bin/env python3
"""Extract the flying bottle sprite from the assisted MAME capture at frame 5754."""
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

capture = Path('build/mission/course-beyond-probe/frame-5754')
palette = (capture / 'palette.bin').read_bytes()
data = (capture / 'videoram0.bin').read_bytes()[0x1800:0x1805]
number, bank, sy, sx, attr = data
assert (number, bank, sy, sx, attr) == (88, 3, 117, 76, 0xc0), tuple(data)
with ZipFile('../ARCADE/original/combatsc.zip') as rom:
    even, odd, prom = (rom.read(n) for n in ('611g07.rom', '611g08.rom', '611g06.h14'))
gfx = bytearray(len(even)*2)
gfx[::2], gfx[1::2] = even, odd
base = (((number + ((bank & 3) << 8) + ((attr & 0xc0) << 4)) << 2)
        + ((bank >> 2) & 3)) & ~3
image = Image.new('RGBA', (16,16))
for ty in range(2):
    for tx in range(2):
        tile = base + (0, 1)[tx] + (0, 2)[ty]
        for y in range(8):
            for x in range(8):
                b = gfx[tile*32+y*4+x//2]
                pen = b >> 4 if x % 2 == 0 else b & 15
                index = prom[(bank >> 4)*16+pen] & 15
                if not index:
                    continue
                colour = palette[index*2] | palette[index*2+1] << 8
                rgb = tuple((((colour >> shift) & 31) << 3) |
                            (((colour >> shift) & 31) >> 2) for shift in (0,5,10))
                image.putpixel((tx*8+x,ty*8+y),(*rgb,255))
out = Path('assets/mission/molotov-flight.png')
image.save(out)
print(out, image.getbbox())
