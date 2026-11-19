#!/usr/bin/env python3
"""Second atlas of the instructor fight from MAME captures.

Sources (all made with the RAM shortcut of tools/mame_step7_capture.lua):
  build/step7/moves        tools/mame_step7_moves.lua (player moves)
  build/step7/win-mame     tools/mame_step7_ko_capture.lua, instructor loses
  build/step7/rules-intro  tools/mame_step7_rules.lua STEP7_SCENARIO=intro
  build/step7/rules-timeout                         STEP7_SCENARIO=timeout
  build/mame-step5         clock digits (same arcade font, 8x13)

Output assets/step7/arcade-extra.png, 256x320 RGBA, stored at VRAM y 1280:
  y 0    instructor punch, facing left / right; sweep, left / right
  y 64   instructor crouching before the punch, left / right; before the
         sweep, left / right
  y 128  player kick wind-up, right / left; recovery after the sweeping
         kick, right / left
  y 192  player jump with the leg out, right / left; kneeling after the
         time runs out, right / left
  y 256  clock digits 0-9 at x 64, ':' at 144 and '.' at 152 (8x13); the
         player turning to the front at x 192
  y 272  "PLAYER 1        CPU"            (arcade x 48, y 80)
  y 280  "(NICK)  (INSTRUCTOR)"          (arcade x 58, y 88)
  y 288  READY at x 0 (arcade 104,64); TIME UP, red, at x 64 (103,64)
  y 296  YOU MADE IT at x 0 (81,104); YOU BLEW IT, red, at x 96 (81,104)
Instructor poses use the same origin as assets/step7/instructor-kick.png
(leftmost sprite), so the punch and the sweep are drawn 16 pixels left of
the instructor; mirrored poses are reflected inside their bounding box.
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_codes

MOVES = Path('build/step7/moves')
PALETTE = (MOVES / 'frame-1136' / 'palette.bin').read_bytes()


def player(parts, ox, oy=116):
    image = Image.new('RGBA', (64, 64))
    for num, bank, attr, x, y in reversed(parts):
        sprite = arcade_codes.entry(num, bank | 0x10, attr, 1, PALETTE, group=4, circuit=1)
        image.alpha_composite(sprite, (x - ox, y - oy))
    return image


def instructor(parts):
    ox = min(x for _, _, x, _ in parts)
    image = Image.new('RGBA', (64, 64))
    for num, attr, x, y in reversed(parts):
        sprite = arcade_codes.entry(num, 3, attr, 0, PALETTE, group=0, circuit=0)
        image.alpha_composite(sprite, (x - ox, y - 116))
    return image


def mirrored(image):
    box = image.getbbox()
    out = Image.new('RGBA', image.size)
    out.alpha_composite(image.crop(box).transpose(Image.Transpose.FLIP_LEFT_RIGHT), box[:2])
    return out


def jump_kick():
    # Airborne: align its lowest pixel with the standing feet (row 63), as
    # the ROM applies the jump height itself.
    image = player([(84, 0, 0xc0, 67, 102), (85, 0, 0xc0, 67, 118), (86, 0, 0xc0, 67, 134), (87, 0, 0xc0, 67, 150)], 59, 102)
    bottom = image.getbbox()[3]
    out = Image.new('RGBA', (64, 64))
    out.alpha_composite(image, (0, 64 - bottom))
    return out


def text(path, box, red):
    a = np.asarray(Image.open(path).convert('RGB')).astype(int)
    x0, y0, x1, y1 = box
    crop = a[y0:y1, x0:x1]
    mask = ((crop[:, :, 0] > 200) & (crop[:, :, 1] < 80)) if red else (crop.min(axis=2) > 200)
    rgba = np.zeros(crop.shape[:2] + (4,), np.uint8)
    rgba[mask] = (240, 8, 8, 255) if red else (248, 248, 240, 255)
    return Image.fromarray(rgba, 'RGBA')


def digits():
    first, seen = 12952, []
    for n in range(13300, 14080, 4):
        cell = np.asarray(Image.open(f'build/mame-step5/combatsc/{(n - first) // 4:04d}.png').convert('RGB'))[26:39, 128:136]
        if cell.max() >= 100 and not any((cell == s).all() for s in seen):
            seen.append(cell.copy())
    assert len(seen) == 10
    glyphs = {}
    for value, cell in zip((2, 1, 0, 9, 8, 7, 6, 5, 4, 3), seen):
        rgba = np.zeros((13, 8, 4), np.uint8)
        rgba[cell.min(axis=2) > 200] = (248, 248, 240, 255)
        glyphs[value] = Image.fromarray(rgba, 'RGBA')
    return glyphs


if __name__ == '__main__':
    atlas = Image.new('RGBA', (256, 320))
    punch = instructor([(116, 0x88, 86, 132), (122, 0x80, 70, 148), (144, 0x80, 86, 164), (145, 0x80, 102, 164)])
    sweep = instructor([(192, 0x80, 82, 132), (60, 0x88, 66, 148), (193, 0x80, 50, 148)])
    crouch = instructor([(120, 0x80, 94, 116), (121, 0x80, 94, 132), (112, 0x88, 86, 148)])
    lowprep = instructor([(194, 0x80, 66, 132), (195, 0x80, 82, 132), (56, 0x88, 66, 148)])
    windup = player([(144, 0, 0xc8, 59, 116), (148, 0, 0xc8, 59, 148)], 59)
    recover = player([(128, 0, 0xc8, 59, 116), (132, 0, 0xc8, 59, 148)], 59)
    kneel = player([(72, 0, 0xc0, 34, 132), (73, 0, 0xc0, 50, 132), (68, 0, 0xc8, 34, 148)], 34)
    turn = player([(88, 0, 0xc8, 82, 116), (92, 0, 0xc8, 82, 148)], 82)
    grid = [[punch, mirrored(punch), sweep, mirrored(sweep)],
            [crouch, mirrored(crouch), lowprep, mirrored(lowprep)],
            [windup, mirrored(windup), recover, mirrored(recover)],
            [jump_kick(), mirrored(jump_kick()), kneel, mirrored(kneel)]]
    for row, images in enumerate(grid):
        for col, image in enumerate(images):
            atlas.alpha_composite(image, (col * 64, row * 64))
    atlas.alpha_composite(turn, (192, 256))
    for value, glyph in digits().items():
        atlas.alpha_composite(glyph, (64 + value * 8, 256))
    intro = 'build/step7/rules-intro/combatsc/%04d.png' % ((900 - 400) // 4)
    timeup = 'build/step7/rules-timeout/combatsc/%04d.png' % ((4560 - 1000) // 20)
    blew = 'build/step7/rules-timeout/combatsc/%04d.png' % ((4700 - 1000) // 20)
    made = 'build/step7/win-mame/combatsc/%04d.png' % ((1252 - 1012) // 4)
    atlas.alpha_composite(text(intro, (112, 26, 120, 39), False), (144, 256))   # ':' of 1:00.0
    atlas.alpha_composite(text(intro, (136, 26, 144, 39), False), (152, 256))   # '.'
    atlas.alpha_composite(text(intro, (48, 80, 160, 88), False), (0, 272))
    atlas.alpha_composite(text(intro, (58, 88, 239, 96), False), (0, 280))
    atlas.alpha_composite(text(intro, (104, 64, 144, 72), False), (0, 288))
    atlas.alpha_composite(text(timeup, (103, 64, 158, 72), True), (64, 288))
    atlas.alpha_composite(text(made, (81, 104, 168, 112), False), (0, 296))
    atlas.alpha_composite(text(blew, (81, 104, 168, 112), True), (96, 296))
    atlas.save('assets/step7/arcade-extra.png')
    print('assets/step7/arcade-extra.png')
