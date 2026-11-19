#!/usr/bin/env python3
"""The arcade's explosion on a hit target (Steps 2 and 6, the same sprites),
from build/mame-shoot-hit (tools/mame_shoot_capture.lua, every frame from
3625: the first wave of Step 2, hit from the left).

Circuit 1, colour bank 0: fire 216 (32x32, 6 frames), fire 220 (6 frames),
then the smoke 224 over 225 (16x32, 12 frames). For a target whose top-left
is at (x, y) the fire's is at (x-8, y+2) and the smoke's at (x, y+2).

Writes assets/shoot/explosion.png: 80x32, fire 216 at x 0, fire 220 at x 32,
smoke at x 64 (transparent background)."""
from pathlib import Path
from PIL import Image
import arcade_sprites

SRC = Path('build/mame-shoot-hit')
# (frame, code(s), sprite-RAM box origin, size, x in the strip)
PARTS = ((3634, {216}, (48, 82), (32, 32), 0),
         (3640, {220}, (48, 82), (32, 32), 32),
         (3646, {224, 225}, (56, 82), (16, 32), 64))

strip = Image.new('RGBA', (80, 32))
for frame, codes, (x, y), (w, h), at in PARTS:
    image = arcade_sprites.render(SRC / f'frame-{frame}', 1, 0, (x, y, x + 1, y + 17), 4, codes)
    part = image.crop((x, y, x + w, y + h))
    assert part.getbbox(), (frame, codes)
    strip.paste(part, (at, 0))
Path('assets/shoot').mkdir(parents=True, exist_ok=True)
strip.save('assets/shoot/explosion.png')
print('assets/shoot/explosion.png:', strip.size)
