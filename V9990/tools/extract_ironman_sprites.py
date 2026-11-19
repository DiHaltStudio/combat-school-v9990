#!/usr/bin/env python3
"""Arcade sprites of the iron man race from tools/mame_ironman_capture.lua.

Renders the K007121 sprites by code from known frames of the capture and
returns RGBA images. Used by tools/build_step3_visual.py.
  log(code)    river log, 32x32 (codes 144 and 148 alternate)
  boat()       free boat, 32x64 (codes 228 bow, 232 stern)
  actor(name, cpu)  runner poses from the CPU's lane, drawn with the CPU's
               colours (bank 0) or the player's (bank 1), cropped to their
               bounding box: run_a/run_b/run_c, swim_a/swim_b, row_a/row_b,
               stand, turn_a/turn_b, fallen (from the player's lane).
"""
import sys
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_sprites

FRAMES = sorted(Path('build/mame-ironman').glob('frame-*'))


def _find(index, circuit, code, near_x=None):
    raw = (FRAMES[index] / f'videoram{circuit}.bin').read_bytes()[0x1800:0x1d00]
    for k in range(64):
        num, bank, sy, sx, attr = raw[k * 5:k * 5 + 5]
        sx -= 256 if attr & 1 else 0
        if num == code and (near_x is None or abs(sx - near_x) < 3):
            return sx, sy, bank >> 4
    raise ValueError(f'sprite {code} not found in shot {index}')


def _sprite(index, circuit, code, near_x=None, size=(32, 32), group=0):
    sx, sy, colour = _find(index, circuit, code, near_x)
    image = arcade_sprites.render(FRAMES[index], circuit, colour, (sx, sy, sx + 1, sy + 1), group, {code})
    return image.crop((sx, sy, sx + size[0], sy + size[1]))


def log(code):
    return _sprite(864 if code == 144 else 866, 0, code)


def boat():
    image = Image.new('RGBA', (32, 64))
    image.paste(_sprite(576, 0, 228, 169), (0, 0))
    image.paste(_sprite(576, 0, 232, 169), (0, 32))
    return image


ACTORS = {   # shot, codes (circuit 1)
    'run_a': (104, (0, 32)), 'run_b': (100, (4, 33)), 'run_c': (111, (8, 34)),
    'turn_a': (60, (24, 38)), 'turn_b': (500, (28, 39)),
    'swim_a': (520, (0, 74, 75)), 'swim_b': (531, (8, 78, 79)),
    'row_a': (701, (212, 216, 244)), 'row_b': (705, (111, 196, 212)),
    'stand': (5, (187, 244)),
    'turn_goal_a': (1005, (44, 73)), 'turn_goal_b': (1010, (48, 74)),
}


def actor(name, cpu):
    if name == 'fallen':
        image = arcade_sprites.render(FRAMES[200], 1, 1, (0, 16, 120, 200), 4, {20, 26, 27},
                                      0 if cpu else 1)
    else:
        shot, codes = ACTORS[name]
        image = arcade_sprites.render(FRAMES[shot], 1, None, (130, 16, 250, 200), 4, set(codes),
                                      0 if cpu else 1)
    return image.crop(image.getbbox())


BOARDING = [(607, (68, 108)), (612, (76,)), (617, (84, 109)), (622, (92, 110)), (627, (100,))]


def boarding(frame, cpu):
    """Boarding frame (0-4) composed with the boat under it, 48x64 centred
    on the boat like the rowing frames."""
    shot, codes = BOARDING[frame]
    boat_x, boat_y, _ = _find(shot, 0, 228)
    canvas = arcade_sprites.render(FRAMES[shot], 0, 0, (boat_x, boat_y, boat_x + 1, boat_y + 1), 0, {228})
    canvas.alpha_composite(arcade_sprites.render(FRAMES[shot], 0, 0, (boat_x, boat_y + 31, boat_x + 1, boat_y + 33), 0, {232}))
    canvas.alpha_composite(arcade_sprites.render(FRAMES[shot], 1, None, (130, 16, 250, 200), 4, set(codes),
                                                 0 if cpu else 1))
    left = boat_x + 16 - 24
    return canvas.crop((left, boat_y, left + 48, boat_y + 64))


def front(top, legs, cpu):
    """Front-facing goal and wading poses drawn from the ROM codes (bank 3)
    with the palette of the CPU's arrival (tools/arcade_codes.py)."""
    import arcade_codes
    palette = (FRAMES[1020] / 'palette.bin').read_bytes()
    return arcade_codes.front_pose(top, legs, 0 if cpu else 1, palette)


def mine_blast(frame):
    """Mine explosion frame 0-9: codes 32+2f and 33+2f side by side (32x16),
    circuit 0 with the mine's bank and attributes, as next to code 53."""
    import arcade_codes
    palette = (FRAMES[200] / 'palette.bin').read_bytes()
    image = Image.new('RGBA', (32, 16))
    for half in range(2):
        part = arcade_codes.entry(32 + 2 * frame + half, 0x01, 0x80, 0, palette, group=0, circuit=0)
        image.paste(part, (half * 16, 0), part)
    return image
