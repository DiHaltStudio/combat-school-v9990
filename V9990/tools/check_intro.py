"""Cartridge introduction (tools/test_intro.tcl) against the arcade capture
(build/mame-intro-full, frames 370..810): each screenshot against the arcade
frame shown at that point, as for the screens before the mission
(tools/check_mission_prelude.py)."""
import json
from pathlib import Path
import numpy as np
from PIL import Image

p = Path('build/demo/intro-test')
P = np.array(json.load(open('assets/mission/prelude.json'))['intro']['palette'], float)


def arcade(n):
    a = np.asarray(Image.open(f'build/mame-intro-full/combatsc/{n - 370:04d}.png').convert('RGB'))
    return a[2:214].astype(float)


worst = 0
for name, first, length in (('slide-up', 377, 114), ('slide-right', 377, 114),
                            ('names-a', 491, 303), ('names-b', 491, 303)):
    left = int((p / f'{name}.txt').read_text())
    f = first + length - left
    rom = np.asarray(Image.open(p / f'{name}.png').convert('RGB')).astype(float)[13:225, 31:287]
    best = None
    for g in range(f - 8, f + 9):    # the screenshot is taken a few frames after the counter is read
        ref = arcade(g)
        q = P[((ref.reshape(-1, 1, 3) - P[None]) ** 2).sum(2).argmin(1)].reshape(ref.shape)
        diff = (np.abs((rom.astype(int) >> 3) - (q.astype(int) >> 3)).max(2) > 1).mean() * 100
        best = diff if best is None else min(best, diff)
    print(f'{name}: arcade frame {f}, {best:.2f}% pixels differ')
    worst = max(worst, best)
assert worst < 4.5, worst          # the slide: portrait rows rounded to 1 pixel
print('OK: the introduction matches the arcade frames within 4.5%')
