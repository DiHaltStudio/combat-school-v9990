#!/usr/bin/env python3
"""Render MAME's unscrolled text tilemap from a captured frame."""
import argparse
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('capture', type=Path)
p.add_argument('--rom', default=str(Path(__file__).resolve().parents[2] / 'ARCADE' / 'original' / 'combatsc.zip'))
p.add_argument('--out', type=Path, default=Path('build/text-layer.png'))
a = p.parse_args()
with ZipFile(a.rom) as z:
    even, odd = z.read('611g07.rom'), z.read('611g08.rom')
    prom = z.read('611g05.h15')
gfx = bytearray(len(even)*2)
gfx[::2], gfx[1::2] = even, odd
ram = (a.capture/'videoram0.bin').read_bytes()
pal = (a.capture/'palette.bin').read_bytes()
assert len(ram) == 8192 and len(pal) == 256
img = Image.new('RGBA', (256,256))
pix = img.load()
for t in range(1024):
    attr, num = ram[0x800+t], ram[0xc00+t]
    for y in range(8):
        for x in range(8):
            byte = gfx[num*32+y*4+x//2]
            pen = byte >> 4 if x%2 == 0 else byte & 15
            index = 16 | (prom[(attr & 15)*16+pen] & 15)
            color = pal[index*2] | pal[index*2+1] << 8
            rgb = tuple((((color >> shift) & 31) << 3) | (((color >> shift) & 31) >> 2) for shift in (0,5,10))
            pix[(t%32)*8+x,(t//32)*8+y] = (*rgb, 255 if pen else 0)
a.out.parent.mkdir(parents=True, exist_ok=True)
img.crop((0,16,256,240)).save(a.out)
