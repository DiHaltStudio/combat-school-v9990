#!/usr/bin/env python3
"""Extract the goal poses of the first event from tools/mame_finish_capture.lua.

Arcade sequence at 60 Hz, player arriving at frame ~2780 with time left:
bent and panting until ~3004, standing up (3012), arm half raised (3020),
arm raised and held from 3028. The instructor raises his baton (2856) and
points it at the runner (2864-2920) before crossing his arms again.
Crops use sprite RAM coordinates so every pose keeps the arcade anchor:
the instructor cell matches build/instructor/2280.png (origin 183,52).
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_sprites

src = Path('build/mame-finish')
out = Path('build/goal'); out.mkdir(parents=True, exist_ok=True)
# Player: circuit 1, colour bank 1, palette group 4; 32x64 cell, feet at row 64.
for name, frame in (('player-bent', 2900), ('player-stand', 3012),
                    ('player-half', 3020), ('player-raised', 3036)):
    image = arcade_sprites.render(src / f'frame-{frame:04d}', 1, 1, (0, 0, 200, 130), 4)
    box = image.getbbox()
    assert box and box[0] >= 72 and box[2] <= 104 and box[1] >= 58 and box[3] <= 122, (name, box)
    image.crop((72, 58, 104, 122)).save(out / f'{name}.png')
# Instructor: circuit 0, colour bank 9, palette group 0; 48x64 cell.
for name, frame in (('instructor-baton', 2856), ('instructor-point', 2880)):
    image = arcade_sprites.render(src / f'frame-{frame:04d}', 0, 9, (100, 0, 256, 130), 0)
    box = image.getbbox()
    assert box and box[0] >= 183 and box[2] <= 231 and box[1] >= 52 and box[3] <= 116, (name, box)
    image.crop((183, 52, 231, 116)).save(out / f'{name}.png')
print('goal poses in', out)
