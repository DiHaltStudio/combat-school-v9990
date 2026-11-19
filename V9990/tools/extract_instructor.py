#!/usr/bin/env python3
"""Extract the instructor's arcade sprites from synchronized MAME captures."""
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

source = Path('build/mame-instructor')
out = Path('build/instructor')
out.mkdir(parents=True, exist_ok=True)
with ZipFile(str(Path(__file__).resolve().parents[2] / 'ARCADE' / 'original' / 'combatsc.zip')) as rom:
    even, odd, prom = [rom.read(name) for name in ('611g07.rom', '611g08.rom', '611g06.h14')]
gfx = bytearray(len(even)*2)
gfx[::2], gfx[1::2] = even, odd
for frame in (804, 876, 888, 2280):
    # MAME 0.286 introduces the first instructor a few frames later.
    candidates = (804, 810) if frame == 804 else (frame,)
    for capture_frame in candidates:
        folder = source / f'frame-{capture_frame:04d}'
        ram = (folder/'videoram0.bin').read_bytes()[0x1800:0x1d00]
        pal = (folder/'palette.bin').read_bytes()
        entries = []
        for i in range(64):
            num, bank, sy, sx, attr = ram[i*5:i*5+5]
            sx -= 256 if attr & 1 else 0
            if bank >> 4 != 9 or sx < 30 or sx > 180:
                continue
            if frame < 2000 and not (40 <= sy < 120):
                continue
            if frame >= 2000 and not (150 <= sy < 224):
                continue
            n = ((num + ((bank & 3) << 8) + ((attr & 0xc0) << 4)) << 2) + ((bank >> 2) & 3)
            typ = attr & 14
            w, h = {6:(1,1),4:(1,2),2:(2,1),0:(2,2),8:(4,4)}.get(typ,(1,1))
            n &= ~(2 if typ == 4 else 1 if typ == 2 else 3 if typ in (0,8) else 0)
            entries.append((sx, sy, n, w, h, attr, bank))
        if entries:
            break
    if not entries:
        raise ValueError(f'no instructor found in frame {frame}')
    minx, miny = min(e[0] for e in entries), min(e[1] for e in entries)
    image = Image.new('RGBA', (48,64))
    for sx, sy, n, w, h, attr, bank in entries:
        for ty in range(h):
            for tx in range(w):
                ex = w-1-tx if attr & 16 else tx
                ey = h-1-ty if attr & 32 else ty
                tile = n + [0,1,4,5][ex] + [0,2,8,10][ey]
                for y in range(8):
                    for x in range(8):
                        px, py = (7-x if attr & 16 else x), (7-y if attr & 32 else y)
                        byte = gfx[tile*32+py*4+px//2]
                        pen = byte >> 4 if px % 2 == 0 else byte & 15
                        lookup = prom[(bank >> 4)*16+pen] & 15
                        if not lookup: continue
                        word = pal[lookup*2] | pal[lookup*2+1] << 8
                        rgb = tuple((((word >> shift) & 31) << 3) | (((word >> shift) & 31) >> 2) for shift in (0,5,10))
                        xx, yy = sx-minx+tx*8+x, sy-miny+ty*8+y
                        if 0 <= xx < 48 and 0 <= yy < 64:
                            image.putpixel((xx,yy), (*rgb,255))
    image.save(out/f'{frame}.png')
