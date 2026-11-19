#!/usr/bin/env python3
"""Build two-palette B1 title and introduction screens from MAME captures."""
from pathlib import Path
from PIL import Image, ImageDraw

out = Path('build/demo')
captures = Path('build/mame-intro/combatsc')
sequence = (16, 18, 19, 20, 21, 22, 23, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 43)

def load(number):
    image = Image.open(captures / f'{number:04}.png').convert('RGB')
    return image.resize((256, 212), Image.Resampling.NEAREST)

title_source = Image.open(captures / '0012.png').convert('RGB')
original = title_source.copy()
draw = ImageDraw.Draw(title_source)
draw.rectangle((144, 210, 255, 223), fill='black')
draw.rectangle((68, 158, 210, 168), fill='black')
# Reuse the game's own pixel font, centered on the line below ONE PLAYER.
glyphs = {'P':(104,144),'R':(144,144),'E':(88,144),'S':(112,160),
          'A':(120,144),'C':(176,216)}
for i,char in enumerate('PRESS SPACE'):
    if char != ' ':
        x,y = glyphs[char]
        title_source.paste(original.crop((x,y,x+8,y+8)), (84+i*8,160))
# The copyright line (© KONAMI 1988, cells x 80..183, rows 200..207)
# becomes DIHALT 2026, centred, with no ©: the arcade's own 8x8 font, the
# same white and shadow (assets/mission/ending-font.png,
# tools/extract_mission_ending.py GLYPHS).
FONT = 'ACDEFGHIKLMNOPRSTUVY0123456789().!>BJQWXZ?#'
font = Image.open('assets/mission/ending-font.png').convert('RGB')
draw.rectangle((80, 200, 183, 207), fill='black')
for i, char in enumerate('DIHALT 2026'):
    if char != ' ':
        k = FONT.index(char) * 8
        title_source.paste(font.crop((k, 0, k + 8, 8)), (88 + i * 8, 200))
title = title_source.resize((256, 212), Image.Resampling.NEAREST)
intro = [load(number) for number in sequence]
sample = Image.new('RGB', (256, 212 * len(intro)))
for i, frame in enumerate(intro):
    sample.paste(frame, (0, i * 212))
quant = sample.quantize(colors=16, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
intro_palette = quant.getpalette()[:48]
reference = Image.new('P', (1, 1))
reference.putpalette(intro_palette + [0] * (768 - len(intro_palette)))
intro_indexed = [frame.quantize(palette=reference, dither=Image.Dither.NONE) for frame in intro]
title_indexed = title.quantize(colors=16, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)

def vram_palette(palette):
    return bytes(value >> 3 for value in palette[:48])

def banked_frame(indexed):
    pixels = list(indexed.getdata())
    assert max(pixels) < 16, 'frame exceeds the B1 palette'
    packed = bytes(pixels[i] * 16 + pixels[i + 1] for i in range(0, len(pixels), 2))
    assert len(packed) == 27136
    return packed + bytes([255]) * (32768 - len(packed))

(out / 'title-palette.bin').write_bytes(vram_palette(title_indexed.getpalette()))
(out / 'intro-palette.bin').write_bytes(vram_palette(intro_palette))
# Keep the full sequence as a build-time reference. Store each distinct
# 32 KiB frame only once in the cartridge and reference it by bank number.
title_blob=banked_frame(title_indexed)
sequence_blobs=list(map(banked_frame, intro_indexed))
(out / 'intro-reference.bin').write_bytes(title_blob+b''.join(sequence_blobs))
unique=[title_blob]
order=[]
for frame in sequence_blobs:
    if frame[:27136] == bytes([255])*27136:
        order.append(255)  # V9990 fill instead of storing a uniform frame.
        continue
    if frame not in unique:
        unique.append(frame)
    order.append(19+2*unique.index(frame))
(out / 'intro.bin').write_bytes(b''.join(unique))
(out / 'intro-order.bin').write_bytes(bytes(order))
assert len(unique)==16 and len(order)==len(sequence)
for original,bank in zip(sequence_blobs,order):
    if bank == 255:
        assert original == bytes([255])*32768
    else:
        assert unique[(bank-19)//2]==original
(out / 'intro.inc').write_text(
    f'INTRO_FRAMES equ {len(sequence)}\n'
    + 'intro_bank_table: db ' + ','.join(map(str,order)) + '\n'
    f'TITLE_BLACK equ {title_indexed.getpixel((0, 0))}\n'
    f'INTRO_BLACK equ {intro_indexed[-1].getpixel((0, 0))}\n'
)
title_indexed.save(out / 'title-preview.png')
intro_indexed[-1].save(out / 'intro-preview.png')
