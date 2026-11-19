#!/usr/bin/env python3
"""Player poses of the instructor fight missing from the first capture.

Sources: tools/mame_step7_moves.lua (build/step7/moves) and the victory of
tools/mame_step7_ko_capture.lua with STEP7_LOSER=instructor STEP7_LAST=1700
(build/step7/win-mame). Circuit-1 sprites, colour 1 (group 4); the 64x64
image has its origin at the player's sprite x and sprite y 116, as the
existing assets/step7/player-*.png:

  player-crouch.png   down held (120, 121, 116)
  player-lowkick.png  down + button 1: sweeping kick (140, 136, 141)
  player-victory.png  arm raised after the instructor is down (220, 224)
"""
import sys
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_codes

POSES = {
    'player-idle-check': ('build/step7/moves/frame-1212', [(104, 0, 0xc8, 0, 0), (108, 0, 0xc8, 0, 32)]),
    'player-crouch': ('build/step7/moves/frame-1184', [(120, 2, 0xc0, 0, 16), (121, 2, 0xc0, 16, 16), (116, 2, 0xc8, 0, 32)]),
    'player-lowkick': ('build/step7/moves/frame-1194', [(140, 0, 0xc0, 0, 16), (136, 0, 0xc8, 0, 32), (141, 0, 0xc0, 32, 32)]),
    'player-victory': ('build/step7/win-mame/frame-1252', [(220, 1, 0xc8, 0, 0), (224, 1, 0xc8, 0, 32)]),
}


def pose(frame, parts):
    palette = (Path(frame) / 'palette.bin').read_bytes()
    image = Image.new('RGBA', (64, 64))
    for num, bank, attr, x, y in reversed(parts):
        sprite = arcade_codes.entry(num, bank | 0x10, attr, 1, palette, group=4, circuit=1)
        image.alpha_composite(sprite, (x, y))
    return image


if __name__ == '__main__':
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('assets/step7')
    for name, (frame, parts) in POSES.items():
        pose(frame, parts).save(out / f'{name}.png')
    print('step 7 poses in', out)
