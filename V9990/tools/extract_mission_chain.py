#!/usr/bin/env python3
"""Extract the chain assailant, preserving the arcade centre/feet anchor.

Requires the assisted MAME chain capture. Does not alter palette or ROM.
The enemy lives in record $0c90, circuit 0, palette group 3 in this capture.
"""
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

root = Path('build/mission/chain-hit')
# The hit probe captures the full reaction and final fall; the observation
# capture supplies the uninterrupted chain attack and walking sequence.
observe = Path('build/mission/chain-trace')
frames = {'walk1': (observe, 7640), 'walk2': (observe, 7654),
          'idle': (observe, 7702), 'raise': (observe, 7774),
          'extend': (observe, 7778), 'recover': (observe, 7688),
          'hit': (root, 7695), 'fall': (root, 7750), 'down': (root, 7800)}
with ZipFile('../ARCADE/original/combatsc.zip') as z:
    even, odd, prom = (z.read(n) for n in ('611g07.rom', '611g08.rom', '611g05.h15'))
# Match MAME combatsc_state::palette: circuit-0 sprites use CLUT 1
# (611g05.h15), despite the ROM labels calling it the character lookup.
gfx = bytearray(len(even)*2)
gfx[::2], gfx[1::2] = even, odd
out = Path('assets/mission/chain'); out.mkdir(parents=True, exist_ok=True)
for name, (base, frame) in frames.items():
    directory = base / f'frame-{frame}'
    ram = (directory/'ram.bin').read_bytes()
    centre = int.from_bytes(ram[0x498:0x49a], 'big') - int.from_bytes(ram[0x1d8:0x1da], 'big')
    palette = (directory/'palette.bin').read_bytes()
    data = (directory/'videoram0.bin').read_bytes()[0x1800:0x1d00]
    image = Image.new('RGBA', (128, 80))
    for i in range(64):
        n, bank, sy, sx, attr = data[i*5:i*5+5]
        sx -= 256 if attr & 1 else 0
        if bank >> 4 != 3 or not centre-64 <= sx <= centre+64 or not 160 <= sy < 224:
            continue
        typ = attr & 14
        w, h = {6:(1,1),4:(1,2),2:(2,1),0:(2,2),8:(4,4)}[typ]
        tile = ((n+((bank&3)<<8)+((attr&0xc0)<<4))<<2)+((bank>>2)&3)
        tile &= ~(2 if typ==4 else 1 if typ==2 else 3 if typ in (0,8) else 0)
        for ty in range(h):
            for tx in range(w):
                ex = w-1-tx if attr&16 else tx
                ey = h-1-ty if attr&32 else ty
                t = tile+(0,1,4,5)[ex]+(0,2,8,10)[ey]
                for y in range(8):
                    for x in range(8):
                        px = 7-x if attr&16 else x
                        py = 7-y if attr&32 else y
                        b = gfx[t*32+py*4+px//2]
                        pen = b>>4 if px%2==0 else b&15
                        index = prom[(bank>>4)*16+pen]&15
                        if not index: continue
                        colour = int.from_bytes(palette[index*2:index*2+2], 'little')
                        rgb = tuple((((colour>>s)&31)<<3)|(((colour>>s)&31)>>2) for s in (0,5,10))
                        xx, yy = sx-centre+64+tx*8+x, sy-160+ty*8+y
                        if 0 <= xx < 128 and 0 <= yy < 80:
                            image.putpixel((xx, yy), (*rgb, 255))
    assert image.getbbox(), (name, frame)
    if name=='down':
        left,top,right,bottom=image.getbbox()
        assert 0<left<right<image.width and bottom<image.height, 'corpse clipped by extraction canvas'
    image.save(out/(name+'.png'))
    print(name, frame, image.getbbox())
