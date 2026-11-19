#!/usr/bin/env python3
"""Extract a ground-fire frame from the assisted arcade capture at frame 5810."""
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

capture = Path('build/mission/course-beyond-probe/frame-5810')
palette = (capture / 'palette.bin').read_bytes()
data = (capture / 'videoram0.bin').read_bytes()[0x1800:0x1d00]
entries = []
for i in range(64):
    number, bank, sy, sx, attr = data[i*5:i*5+5]
    if (number, bank, sy, sx, attr) in ((93,3,176,146,0xc0),(100,3,192,138,0xc8)):
        entries.append((number, bank, sy, sx, attr))
assert len(entries)==2, entries
with ZipFile('../ARCADE/original/combatsc.zip') as rom:
    even, odd, prom = (rom.read(n) for n in ('611g07.rom', '611g08.rom', '611g06.h14'))
gfx = bytearray(len(even)*2)
gfx[::2], gfx[1::2] = even, odd
image = Image.new('RGBA', (32,48))
for number, bank, sy, sx, attr in entries:
    typ = attr & 14
    width, height = {0:(2,2), 8:(4,4)}[typ]
    base = (((number + ((bank & 3) << 8) + ((attr & 0xc0) << 4)) << 2)
            + ((bank >> 2) & 3)) & ~3
    for ty in range(height):
        for tx in range(width):
            ex = width-1-tx if attr & 16 else tx
            ey = height-1-ty if attr & 32 else ty
            tile = base + (0,1,4,5)[ex] + (0,2,8,10)[ey]
            for y in range(8):
                for x in range(8):
                    px = 7-x if attr & 16 else x
                    py = 7-y if attr & 32 else y
                    b = gfx[tile*32+py*4+px//2]
                    pen = b >> 4 if px%2==0 else b&15
                    index = prom[(bank>>4)*16+pen]&15
                    if not index:
                        continue
                    colour = palette[index*2] | palette[index*2+1]<<8
                    rgb = tuple((((colour>>shift)&31)<<3)|(((colour>>shift)&31)>>2)
                                for shift in (0,5,10))
                    image.putpixel((sx-138+tx*8+x,sy-176+ty*8+y),(*rgb,255))
out = Path('assets/mission/molotov-fire.png')
image.save(out)
print(out,image.getbbox())
