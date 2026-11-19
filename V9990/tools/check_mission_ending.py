"""Arcade ending (tools/test_mission_ending.tcl) against the MAME captures:
the mansion (build/mission/ending-mame-early, frames 8000..9400) and the
text screens (build/mission/ending-mame, frames 9000..12850), both colour
depths reduced to 5 bits per component.

The rank screen's last two text rows sit 12 lines higher (212 lines for
the arcade's 224); the RANKING table differs only in the player's name
(the arcade waits for initials, cells 16..21 of the first row)."""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image

p = Path('build/mission/ending-test')
EARLY = Path('build/mission/ending-mame-early/combatsc')
LATE = Path('build/mission/ending-mame/combatsc')


def arcade(n):
    path = EARLY / f'{n - 8000:04d}.png' if n <= 9400 else LATE / f'{n - 9000:04d}.png'
    return np.asarray(Image.open(path).convert('RGB')).astype(int)


def rom(name):
    # openMSX raw screenshot: 320 x 240 with borders.
    return np.asarray(Image.open(p / f'{name}.png').convert('RGB')).astype(int)[13:225, 31:287]


def differ(a, b, mask=None):
    d = np.abs((a >> 3) - (b >> 3)).max(2) > 1
    if mask is not None:
        d = d[mask]
    return d.mean() * 100


worst = 0
# Mansion: frames left when shown; the screen has 466 frames.
# 33 arcade colours in 16 (k-means, tools/extract_mission_prelude.py): a
# pixel differs when the ROM colour is clearly farther from the arcade one
# than the nearest palette colour.
P = np.array(json.load(open('assets/mission/prelude.json'))['ending']['palette'])
def mansion_differ(r, a):
    best = np.sqrt(((a.reshape(-1, 1, 3) - P[None]) ** 2).sum(2).min(1)).reshape(a.shape[:2])
    got = np.sqrt(((r - a) ** 2).sum(2))
    return (got > best + 24).mean() * 100
left = int((p / 'mansion.txt').read_text())
f = 8866 + 466 - left
best = min(mansion_differ(rom('mansion'), arcade(g)[6:218]) for g in range(f - 2, f + 3))
print(f'mansion: arcade frame {f}, {best:.2f}% pixels differ')
worst = max(worst, best)

# Rank screen: rows 0..199 as in the arcade, then rows 208..223 at 196.
r = rom('rank')
best = None
for g in range(9498, 9503):
    a = arcade(g)
    ref = np.vstack([a[0:196], a[208:224]])
    v = differ(r, ref)
    best = v if best is None else min(best, v)
print(f'rank screen: {best:.2f}% pixels differ')
worst = max(worst, best)

v = differ(rom('congrats'), arcade(10300)[0:212])
print(f'congratulations: {v:.2f}% pixels differ')
worst = max(worst, v)

mask = np.ones((212, 256), bool)
mask[56:64, 128:184] = False
best = min(differ(rom('ranking'), arcade(g)[0:212], mask) for g in range(10698, 10703))
print(f'ranking: {best:.2f}% pixels differ')
worst = max(worst, best)

after = rom('after')
sig, *initials = (p / 'done.txt').read_text().split()
assert sig == '6783', 'RANKING table signature'
glyphs = json.load(open('assets/mission/ending.json'))['glyphs']
assert ''.join(glyphs[int(g)] for g in initials) == 'CCD', initials
print('initials typed: CCD, first in the RANKING table')
print('after the ending:', 'black' if after.max() < 16 else 'picture')
assert worst < 2.0, worst
print('OK: the ending matches the arcade frames within 2%')
