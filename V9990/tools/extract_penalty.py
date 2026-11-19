#!/usr/bin/env python3
"""Arcade graphics of the penalty (chin-ups) from MAME captures.

Sources, made with tools/mame_penalty_rules.lua (PEN_SCEN=chinup, Step 1
lost 5 pixels from the goal):
  build/penalty/portrait  PEN_PERIOD=8 PEN_FIRST=3384 PEN_STEP=4  instructor
  build/penalty/chin      PEN_PERIOD=8 PEN_FIRST=3960 PEN_STEP=10 chin-ups won
  build/penalty/fail      no presses, PEN_FIRST=5200 PEN_STEP=30   time up
  build/penalty/h40, h43  tools/mame_penalty_ram.lua PEN_HITS=40/43 (10, 07)
  build/penalty/rest/r32, r96, r128  tools/mame_penalty_probe.lua (06, 08, 09)
Coordinates are those of the arcade screenshot (the score line is rows
0..15), as in the other ROM screens; the ROM shows rows 0..211.

Outputs in assets/penalty:
  scene.png     256x212 background: tiles, bars, the soldier on the left,
                COMPLETE AS A PENALTY, POWER and the empty bar (moved up
                eight rows so that they fit in 212 lines)
  portrait.png  256x212 instructor (moved up 12 rows), stick down, mouth shut
  portrait-stick.png  stick raised, opaque patch at PORTRAIT_STICK
  portrait-mouth.png  two mouth shapes side by side, at PORTRAIT_MOUTH
  poses.png     256x192 atlas of 32x64 cells (POSES order, screen position
                of each cell in poses.txt)
  labels.png    256x64: texts, count digits (8x8) and clock digits (8x13)
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parent))
import arcade_codes

B = Path('build/penalty')
OUT = Path('assets/penalty')
PORTRAIT_SHIFT = 12
PORTRAIT_STICK = (68, 90 - PORTRAIT_SHIFT, 104, 112)     # x, y, w, h (ROM rows)
PORTRAIT_MOUTH = (112, 80 - PORTRAIT_SHIFT, 52, 52)
# Pose name -> (capture, frame). NICK: circuit 1 bank 0x13 (colour 1);
# JOE: circuit 0 bank 0x62 (colour 6).
NICK = [('stand', 'chin', 3990), ('crouch', 'chin', 4200), ('grab', 'chin', 4220),
        ('hang0', 'chin', 4240), ('hang1', 'chin', 4250), ('pull', 'chin', 4280),
        ('top', 'chin', 4300), ('top2', 'chin', 4310), ('lower', 'chin', 4320),
        ('made1', 'chin', 5020), ('made2', 'chin', 5050),
        ('fall1', 'fail', 5620), ('fall2', 'fail', 5650), ('sit', 'fail', 5680)]
JOE = [('joe', 'chin', 3990), ('joe2', 'chin', 4200),
       ('walkl0', 'chin', 4440), ('walkl1', 'chin', 4470), ('walkl2', 'chin', 4490),
       ('walkr0', 'chin', 4780), ('walkr1', 'chin', 4810), ('walkr2', 'chin', 4830)]


def shot(d, base, step, frame):
    return Image.open(B / d / 'combatsc' / ('%04d.png' % ((frame - base) // step))).convert('RGB')


def sprites(frame_dir):
    out = {}
    for c in (0, 1):
        v = (frame_dir / f'videoram{c}.bin').read_bytes()[0x1800:0x1800 + 320]
        out[c] = []
        for i in range(64):
            num, bank, sy, sx, attr = v[i * 5:i * 5 + 5]
            if attr & 1:
                sx -= 256
            if sx > -32 and sy < 224:
                out[c].append((num, bank, sy, sx, attr))
    return out


def pose(capture, frame, joe):
    """Cell 32x64 whose top-left is at (min x, min y - 16) on screen."""
    d = B / capture / f'frame-{frame}'
    palette = (d / 'palette.bin').read_bytes()
    found = sprites(d)
    if joe:
        parts = [p for p in found[0] if p[1] == 0x62]
    else:
        parts = [p for p in found[1] if p[1] == 0x13]
    assert parts, (capture, frame)
    ox, oy = min(p[3] for p in parts), min(p[2] for p in parts)
    cell = Image.new('RGBA', (32, 64))
    for num, bank, sy, sx, attr in reversed(parts):
        if joe:
            spr = arcade_codes.entry(num, bank, attr, 6, palette, group=0, circuit=0)
        else:
            spr = arcade_codes.entry(num, bank, attr, 1, palette, group=4, circuit=1)
        cell.alpha_composite(spr, (sx - ox, sy - oy))
    return cell, ox, oy - 16


def text(image, box, colour):
    a = np.asarray(image).astype(int)
    x0, y0, x1, y1 = box
    crop = a[y0:y1, x0:x1]
    if colour == 'white':
        mask = crop.min(axis=2) > 200
        rgba = (248, 248, 240, 255)
    else:
        mask = (crop[:, :, 0] > 200) & (crop[:, :, 1] < 80)
        rgba = (240, 8, 8, 255)
    out = np.zeros(crop.shape[:2] + (4,), np.uint8)
    out[mask] = rgba
    return Image.fromarray(out, 'RGBA')


def scene():
    d = B / 'chin' / 'frame-4290'
    palette = (d / 'palette.bin').read_bytes()
    image = Image.open(B / 'bg-4290' / 'plane1.png').convert('RGBA')
    for num, bank, sy, sx, attr in reversed(sprites(d)[1]):
        if bank == 0x00 and attr == 0x80:                       # bars
            image.alpha_composite(arcade_codes.entry(num, 0, attr, 0, palette, group=4, circuit=1), (sx, sy - 16))
    for num, attr, x, y in reversed([(44, 128, 36, 128), (40, 136, 28, 144), (45, 128, 36, 176)]):
        image.alpha_composite(arcade_codes.entry(num, 0x03, attr, 0, palette, group=4, circuit=1), (x, y - 16))
    first = shot('chin', 3960, 10, 4960)
    image.alpha_composite(text(first, (40, 54, 208, 64), 'white'), (40, 54))
    image = image.convert('RGB')
    image.paste((0, 0, 0), (0, 0, 256, 16))                    # score line
    # POWER (x 15..44) and the empty bar (x 48..111), rows 209..214 -> 201.
    power = first.crop((0, 205, 128, 216))
    image.paste(power, (0, 197))
    return image.crop((0, 0, 256, 212)), palette


def portrait():
    p = lambda f: shot('portrait', 3384, 4, f)
    base = p(3420).crop((0, PORTRAIT_SHIFT, 256, 212 + PORTRAIT_SHIFT))
    up = p(3444).crop((0, PORTRAIT_SHIFT, 256, 212 + PORTRAIT_SHIFT))
    x, y, w, h = PORTRAIT_STICK
    stick = up.crop((x, y, x + w, y + h))
    x, y, w, h = PORTRAIT_MOUTH
    mouth = Image.new('RGB', (2 * w, h))
    for k, f in enumerate((3504, 3556)):
        mouth.paste(p(f).crop((0, PORTRAIT_SHIFT, 256, 212 + PORTRAIT_SHIFT)).crop((x, y, x + w, y + h)), (k * w, 0))
    return base, stick, mouth


def labels():
    """Texts at y 0..31, count digits 0-9 at (0,32), clock digits at (0,40)."""
    atlas = Image.new('RGBA', (256, 64))
    intro, talk = shot('chin', 3960, 10, 4180), shot('chin', 3960, 10, 4960)
    atlas.alpha_composite(text(intro, (32, 88, 104, 104), 'white'), (0, 0))       # PLAYER 1 / (NICK)
    atlas.alpha_composite(text(talk, (128, 88, 224, 104), 'white'), (72, 0))      # TAKE A BREAK / (JOE)
    # The capture still types "(JOE"; copy the closing bracket of (NICK)
    # with the same gap after the last letter.
    nick = np.asarray(atlas.crop((0, 8, 72, 16)))[:, :, 3].any(axis=0)
    cols = np.nonzero(nick)[0]
    gaps = np.nonzero(np.diff(cols) > 1)[0]
    paren, k_end = cols[gaps[-1] + 1], cols[gaps[-1]]
    joe = np.nonzero(np.asarray(atlas.crop((72, 8, 168, 16)))[:, :, 3].any(axis=0))[0]
    atlas.alpha_composite(atlas.crop((paren, 8, cols[-1] + 1, 16)), (72 + joe[-1] + paren - k_end, 8))
    atlas.alpha_composite(text(shot('chin', 3960, 10, 5040), (16, 120, 48, 128), 'white'), (168, 0))   # YOU
    atlas.alpha_composite(text(shot('fail', 5200, 30, 5710), (16, 120, 48, 128), 'red'), (200, 0))    # YOU
    atlas.alpha_composite(text(shot('fail', 5200, 30, 5890), (88, 88, 160, 96), 'red'), (168, 8))     # GAME OVER
    # Count digits 8x8, from the two-digit count at x 56..71, y 191..198.
    seen = {}
    for src, value in (((B / 'chin', 3960, 10, 4250), '05'), ((B / 'chin', 3960, 10, 4350), '04'),
                       ((B / 'chin', 3960, 10, 4450), '03'), ((B / 'chin', 3960, 10, 4550), '02'),
                       ((B / 'chin', 3960, 10, 4650), '01'), ((B / 'h40', 5400, 30, 7020), '10'),
                       ((B / 'h43', 5400, 30, 7020), '07'), ((B / 'rest/r32', 2900, 100, 4100), '06'),
                       ((B / 'rest/r96', 2900, 100, 4100), '08'), ((B / 'rest/r128', 2900, 100, 4100), '09')):
        d, base, step, frame = src
        image = Image.open(d / 'combatsc' / ('%04d.png' % ((frame - base) // step))).convert('RGB')
        for k, ch in enumerate(value):
            glyph = text(image, (56 + 8 * k, 191, 64 + 8 * k, 199), 'white')
            seen.setdefault(int(ch), glyph)
    assert sorted(seen) == list(range(10)), sorted(seen)
    for value, glyph in seen.items():
        atlas.alpha_composite(glyph, (value * 8, 32))
    # Clock digits, ':' and '.', the same arcade font as Step 7.
    extra = Image.open('assets/step7/arcade-extra.png').convert('RGBA')
    atlas.alpha_composite(extra.crop((64, 256, 160, 269)), (0, 40))
    red = np.asarray(atlas.crop((0, 40, 96, 53))).copy()
    red[red[:, :, 3] > 0] = (240, 8, 8, 255)
    atlas.alpha_composite(Image.fromarray(red, 'RGBA'), (96, 40))
    return atlas


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    image, palette = scene()
    image.save(OUT / 'scene.png')
    base, stick, mouth = portrait()
    base.save(OUT / 'portrait.png'); stick.save(OUT / 'portrait-stick.png'); mouth.save(OUT / 'portrait-mouth.png')
    atlas = Image.new('RGBA', (256, 192))
    rows = []
    for k, (name, capture, frame) in enumerate(NICK + JOE):
        cell, x, y = pose(capture, frame, k >= len(NICK))
        atlas.alpha_composite(cell, ((k % 8) * 32, (k // 8) * 64))
        rows.append(f'{name} {x} {y}')
    atlas.save(OUT / 'poses.png')
    (OUT / 'poses.txt').write_text('\n'.join(rows) + '\n')
    labels().save(OUT / 'labels.png')
    print('penalty graphics in', OUT)
