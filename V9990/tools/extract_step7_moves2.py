#!/usr/bin/env python3
"""Player poses of the instructor fight that the port lacked (16-nov).

Source: the MAME capture of every move (a research script, its log
moves.txt and frame dumps every 2 frames; kept in
../build/capture-archives/20261116T172820701380Z/step7/moves2):

  player-backwalk1/2  stepping back, still facing the opponent (88, 96)
  player-tuck         somersault of the jumps, knees up (84)
  player-stretch      somersault, stretched (112)
  player-airkick      button 1 during a jump (116)
  player-highkick1..6 up-forward + button 1 (139, 142, 152, 160, 164, 232)

Circuit-1 sprites, colour 1 (group 4), as tools/extract_step7_moves.py. The
64x64 image has its origin at the player's x - 16 and sprite y 116, as
assets/step7/player-*.png; the poses in the air are put with their feet at
the standing pose's (the game adds the jump height).

usage: extract_step7_moves2.py [capture dir] [out dir]"""
import sys
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_codes

ROOT = Path(__file__).resolve().parents[2]
CAPTURE = Path(sys.argv[1]) if len(sys.argv) > 1 else \
    ROOT / 'build/capture-archives/20261116T172820701380Z/step7/moves2'
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else Path('assets/step7')
# name: (frame, player x, sprites num/bank/attr@x,y, in the air)
POSES = {
    'player-backwalk1': (1484, 94, '88/0/c8@78,116 92/0/c8@78,148', False),
    'player-backwalk2': (1452, 96, '96/0/c8@80,116 100/0/c8@80,148', False),
    'player-tuck': (1856, 96, '84/0/c0@88,111 85/0/c0@88,127 86/0/c0@88,143 87/0/c0@88,159', True),
    'player-stretch': (1864, 96, '112/0/c8@80,89 81/0/c0@88,121', True),
    'player-airkick': (2118, 96, '116/0/c8@80,94 120/0/c0@88,126 121/0/c0@112,118', True),
    'player-highkick1': (1536, 97, '139/1/c0@89,116 144/1/c8@81,132 140/1/c0@89,164', False),
    'player-highkick2': (1540, 97, '142/1/c0@89,116 148/1/c8@81,132 141/1/c0@81,164', False),
    'player-highkick3': (1544, 97, '152/1/c8@81,132 156/1/c0@113,132 143/1/c0@89,164', False),
    'player-highkick4': (1548, 97, '160/1/c8@81,132 157/1/c0@89,164', False),
    'player-highkick5': (1552, 97, '164/1/c8@81,132 158/1/c0@81,164 159/1/c0@97,164', False),
    'player-highkick6': (1556, 97, '232/1/c8@81,132 236/1/c0@81,164 237/1/c0@97,164', False),
}
GROUND = 180          # the standing pose's feet (sprite 108 at y 148, 32 high)


def size(attr):
    return 32 if attr & 0x08 else 16


def pose(frame, px, sprites, air):
    palette = (CAPTURE / f'frame-{frame}' / 'palette.bin').read_bytes()
    parts = []
    for s in sprites.split():
        code, at = s.split('@')
        num, bank, attr = code.split('/')
        x, y = map(int, at.split(','))
        parts.append((int(num), int(bank), int(attr, 16), x, y))
    dy = 0
    if air:
        dy = GROUND - max(y + size(attr) for _, _, attr, _, y in parts)
    image = Image.new('RGBA', (64, 64))
    for num, bank, attr, x, y in reversed(parts):
        sprite = arcade_codes.entry(num, bank | 0x10, attr, 1, palette, group=4, circuit=1)
        image.alpha_composite(sprite, (x - (px - 16), y + dy - 116))
    return image


if __name__ == '__main__':
    for name, (frame, px, sprites, air) in POSES.items():
        pose(frame, px, sprites, air).save(OUT / f'{name}.png')
    print('step 7 moves:', ', '.join(POSES))
