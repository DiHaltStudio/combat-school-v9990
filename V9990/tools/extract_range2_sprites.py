#!/usr/bin/env python3
"""Arcade sprites of Firing Range II (Step 4) from tools/mame_range2_capture.lua.

Targets are circuit-0 sprites (bank 1, colour 0). The ROM uses five sizes
by depth, chosen from the screen rows where the arcade shows each code:
front 144/146/148/152/160 and side 200/200/206/212/168.

The shooter is made of circuit-1 sprites (colour 1, group 4) inside a
32x64 box whose top-left is the sprite position of its upper part; the
ROM keeps rows 4..63 (60 rows, the raised arm reaches row 5). Poses:
idle, right stride/close, left stride/close (mirrored), standing up and
arm raised (frames 12592 and 12624 of the capture).

Outputs assets/step4/arcade-targets.png (two rows of 32: front and side)
and assets/step4/arcade-shooter.png (seven 32x60 frames).
"""
import sys
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_codes

SOURCE = Path('build/mame-range2')
PALETTE = (SOURCE / 'frame-12000' / 'palette.bin').read_bytes()
FRONT = [(144, 0x80), (146, 0x80), (148, 0x80), (152, 0x88), (160, 0x88)]
SIDE = [(200, 0x80), (200, 0x80), (206, 0x80), (212, 0x88), (168, 0x88)]
SHOOTER = {
    'idle': [(76, 2, 0xc0, 8, 0), (68, 2, 0xc8, 0, 16), (78, 2, 0xc0, 0, 48), (79, 2, 0xc0, 16, 48)],
    'right-stride': [(108, 2, 0xc8, 0, 0), (96, 2, 0xc8, 0, 32)],
    'right-close': [(104, 2, 0xc8, 0, 0), (84, 2, 0xc8, 0, 32)],
    'left-stride': [(108, 2, 0xd8, 0, 0), (96, 2, 0xd8, 0, 32)],
    'left-close': [(104, 2, 0xd8, 0, 0), (84, 2, 0xd8, 0, 32)],
    'stand': [(201, 3, 0x80, 8, 0), (228, 3, 0x88, 0, 16), (236, 3, 0x80, 8, 48)],
    'raised': [(232, 3, 0x88, 0, 0), (237, 3, 0x80, 8, 32), (236, 3, 0x80, 8, 48)],
}


def target(num, attr):
    image = arcade_codes.entry(num, 1, attr, 0, PALETTE, group=0, circuit=0)
    return image.crop(image.getbbox())


def shooter(parts):
    box = Image.new('RGBA', (32, 64))
    for num, bank, attr, x, y in reversed(parts):   # first entry on top
        sprite = arcade_codes.entry(num, bank, attr, 1, PALETTE, group=4, circuit=1)
        box.alpha_composite(sprite, (x, y))
    return box.crop((0, 4, 32, 64))


if __name__ == '__main__':
    out = Path('assets/step4')
    sheet = Image.new('RGBA', (5 * 32, 64))
    for row, codes in enumerate((FRONT, SIDE)):
        for band, (num, attr) in enumerate(codes):
            sheet.alpha_composite(target(num, attr), (band * 32, row * 32))
    sheet.save(out / 'arcade-targets.png')
    poses = Image.new('RGBA', (7 * 32, 60))
    for k, parts in enumerate(SHOOTER.values()):
        poses.alpha_composite(shooter(parts), (k * 32, 0))
    poses.save(out / 'arcade-shooter.png')
    print('step 4 arcade sprites in', out)
