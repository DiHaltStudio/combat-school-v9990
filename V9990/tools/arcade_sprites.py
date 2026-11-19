#!/usr/bin/env python3
"""Render K007121 sprites of a synchronized MAME capture at screen positions.

Shared by the goal-pose extraction. It follows tools/extract_instructor.py;
here both circuits are supported and the result keeps the arcade's screen
placement, so poses from different frames share one anchor.
"""
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

ROM = Path(__file__).resolve().parents[2] / 'ARCADE' / 'original' / 'combatsc.zip'
NAMES = (('611g07.rom', '611g08.rom', '611g06.h14'), ('611g11.rom', '611g12.rom', '611g10.h6'))
_gfx = {}

def _load(circuit):
    if circuit not in _gfx:
        with ZipFile(ROM) as z:
            even, odd, prom = [z.read(n) for n in NAMES[circuit]]
        gfx = bytearray(len(even) * 2)
        gfx[::2], gfx[1::2] = even, odd
        _gfx[circuit] = (gfx, prom)
    return _gfx[circuit]

def render(capture, circuit, colour, box, group=0, codes=None, as_colour=None):
    """Sprites of colour bank `colour` whose origin lies in box (x0,y0,x1,y1,
    sprite RAM coordinates), optionally only those whose code is in `codes`.
    colour=None accepts any colour bank; as_colour draws them with another
    bank (for example the player's colours on a CPU pose).
    Returns a 256x256 RGBA image in those coordinates."""
    capture = Path(capture)
    gfx, prom = _load(circuit)
    ram = (capture / f'videoram{circuit}.bin').read_bytes()[0x1800:0x1d00]
    pal = (capture / 'palette.bin').read_bytes()
    image = Image.new('RGBA', (256, 256))
    x0, y0, x1, y1 = box
    for i in range(64):
        num, bank, sy, sx, attr = ram[i*5:i*5+5]
        sx -= 256 if attr & 1 else 0
        if (colour is not None and bank >> 4 != colour) or not (x0 <= sx < x1 and y0 <= sy < y1):
            continue
        if codes is not None and num not in codes:
            continue
        n = ((num + ((bank & 3) << 8) + ((attr & 0xc0) << 4)) << 2) + ((bank >> 2) & 3)
        typ = attr & 14
        w, h = {6: (1, 1), 4: (1, 2), 2: (2, 1), 0: (2, 2), 8: (4, 4)}.get(typ, (1, 1))
        n &= ~(2 if typ == 4 else 1 if typ == 2 else 3 if typ in (0, 8) else 0)
        for ty in range(h):
            for tx in range(w):
                ex = w-1-tx if attr & 16 else tx
                ey = h-1-ty if attr & 32 else ty
                tile = n + [0, 1, 4, 5][ex] + [0, 2, 8, 10][ey]
                for y in range(8):
                    for x in range(8):
                        px, py = (7-x if attr & 16 else x), (7-y if attr & 32 else y)
                        byte = gfx[tile*32 + py*4 + px//2]
                        pen = byte >> 4 if px % 2 == 0 else byte & 15
                        lookup = prom[((bank >> 4) if as_colour is None else as_colour)*16 + pen] & 15
                        if not lookup:
                            continue
                        idx = group*16 + lookup
                        word = pal[idx*2] | pal[idx*2+1] << 8
                        rgb = tuple((((word >> s) & 31) << 3) | (((word >> s) & 31) >> 2) for s in (0, 5, 10))
                        xx, yy = sx + tx*8 + x, sy + ty*8 + y
                        if 0 <= xx < 256 and 0 <= yy < 256:
                            image.putpixel((xx, yy), (*rgb, 255))
    return image
