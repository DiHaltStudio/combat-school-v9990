#!/usr/bin/env python3
"""Arcade targets of Firing Range III (Step 6) from tools/mame_step6_capture.lua.

Each board is a circuit-0 sprite pair at sprite y 80 (board) and 96 (post);
on screen y = 80 - 16 - 14 = 50 in ROM coordinates. Ring boards use colour 0
and the red boards with a soldier colour 2. Three states, measured in MAME:
standing (246/247, 22/23), half-raised for 4 frames while rising or falling
(248/249, 24/25) and lying on the ground (255, 26; post code only).

Output: assets/step6/arcade-targets.png, six 16x32 frames: ring and red
standing, ring and red half-raised, ring and red lying.
"""
import sys
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_codes

PALETTE = Path('build/mame-step6b/frame-2000/palette.bin').read_bytes()
FRAMES = [((246, 247), 0x02), ((22, 23), 0x22), ((248, 249), 0x02),
          ((24, 25), 0x22), ((None, 255), 0x02), ((None, 26), 0x22)]

if __name__ == '__main__':
    sheet = Image.new('RGBA', (96, 32))
    for k, ((board, post), bank) in enumerate(FRAMES):
        for code, y in ((board, 0), (post, 16)):
            if code is not None:
                sprite = arcade_codes.entry(code, bank, 0x80, bank >> 4, PALETTE, group=0, circuit=0)
                sheet.alpha_composite(sprite, (k * 16, y))
    sheet.save('assets/step6/arcade-targets.png')
    print('assets/step6/arcade-targets.png')
