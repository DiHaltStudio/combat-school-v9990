#!/usr/bin/env python3
"""Arcade graphics of the first firing range from tools/mame_shoot_capture.lua.

The ROM field is the arcade screen moved 14 pixels up (ROM y = arcade y - 14,
same x). Targets are circuit-0 sprites of colour bank 0: a 16x16 board over a
16x16 stand. Codes 242/243 are the middle-distance target and 246/247 the
near one. The qualified shooter stands up at frame 5904 and raises his arm
from 5920; the patches cover the ROM pose rectangle x=40..87, y=130..193.
The background planes of this scene use the captured vreg (0x40).
"""
import subprocess
import sys
from pathlib import Path
from PIL import Image, ImageFilter
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_sprites

SOURCE = Path('build/mame-shoot')
ROM_DY = 14


def _capture(frame):
    return SOURCE / f'frame-{frame:04d}'


def _snapshot(frame):
    frames = sorted(SOURCE.glob('frame-*'))
    shots = sorted((SOURCE / 'combatsc').glob('*.png'))
    return Image.open(shots[[f.name for f in frames].index(f'frame-{frame:04d}')]).convert('RGB')


def _target(frame, head, stand, x, y, height):
    """Board and stand at sprite position (x, y), cropped to 16 x height
    from the board's first row."""
    image = arcade_sprites.render(_capture(frame), 0, 0, (x, y, x + 1, y + 17), 0, {head, stand})
    image = image.crop((x, y, x + 16, y + 32))
    top = image.getbbox()[1]
    image = image.crop((0, top, 16, top + height))
    assert image.getbbox()[3] <= height, ('target taller than its slot', head, image.getbbox())
    return image


def target_images():
    """Middle-distance target (16x24) and near target (16x32), RGBA."""
    return (_target(3632, 242, 243, 56, 80, 24),
            _target(4016, 246, 247, 146, 144, 32))


SHIRT = {(239, 99, 0), (222, 140, 16)}


def _planes(frame):
    """Arcade background without sprites (both tile planes), screen coords."""
    out = Path('build/shoot-goal/planes')
    subprocess.run([sys.executable, 'tools/render_background.py', str(_capture(frame)),
                    '--out', str(out)], check=True, stdout=subprocess.DEVNULL)
    image = Image.open(out / 'plane1.png').convert('RGBA')
    image.alpha_composite(Image.open(out / 'plane0.png').convert('RGBA'))
    return image.convert('RGB')


def _shooter(frame):
    """Player shooter sprites (circuit 1, colour 1, group 4), in ROM coordinates."""
    image = arcade_sprites.render(_capture(frame), 1, 1, (0, 130, 120, 232), 4)
    return image.crop((0, 30, 256, 242))


def celebration_patches(field):
    """Standing and arm-raised 48x64 patches for x=40..87, y=130..193.

    The ROM field (captured from video) keeps its own colours. Only the arcade
    shooter sprites are drawn over it; where the field's crouching shooter
    is no longer covered, the arcade background planes show through.
    Returns (RGB patch, set of shirt pixel positions) pairs."""
    crouch = Image.new('1', (48, 64))
    for frame in range(3600, 5900, 16):
        sprite = _shooter(frame).crop((40, 130, 88, 194))
        crouch.paste(1, (0, 0), sprite.getchannel('A').point(lambda a: 255 if a else 0))
    # One pixel of margin for video blur around the captured crouching pose.
    crouch = crouch.filter(ImageFilter.MaxFilter(3))
    background = _planes(5936).crop((40, 130 + ROM_DY, 88, 194 + ROM_DY))
    base = field.crop((40, 130, 88, 194))
    base.paste(background, (0, 0), crouch)
    patches = []
    for frame in (5904, 5936):
        sprite = _shooter(frame).crop((40, 130, 88, 194))
        patch = base.copy()
        patch.paste(sprite.convert('RGB'), (0, 0), sprite.getchannel('A'))
        shirt = {(x, y) for y in range(64) for x in range(48)
                 if sprite.getpixel((x, y))[3] and sprite.getpixel((x, y))[:3] in SHIRT}
        patches.append((patch, shirt))
    return patches


if __name__ == '__main__':
    out = Path('build/shoot-goal'); out.mkdir(parents=True, exist_ok=True)
    middle, near = target_images()
    middle.save(out / 'target-middle.png'); near.save(out / 'target-near.png')
    for name, (patch, _) in zip(('stand', 'raised'), celebration_patches(Image.open('assets/shoot/field.png').convert('RGB'))):
        patch.save(out / f'pose-{name}.png')
    print('firing range goal graphics in', out)
