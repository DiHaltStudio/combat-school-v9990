#!/usr/bin/env python3
"""Qualified Step 4 ending (tools/test_step4_goal.tcl): the shooter stands up
and raises his arm, and the centred labels replace the top one."""
from pathlib import Path
from PIL import Image

out = Path('build/step4/goal')
assert (out / 'state.txt').read_text().split() == ['1', '0', '0']
shot = lambda n: Image.open(out / f'{n}.png').convert('RGB')
# Raw screenshots have 31,13 border offsets. Shooter box: x 110..141, y 134..193.
def box(image, x0, y0, x1, y1):
    return list(image.crop((x0 + 31, y0 + 13, x1 + 31, y1 + 13)).getdata())
idle, stand, raised, labels = (shot(n) for n in ('end-idle', 'end-stand', 'end-raised', 'end-labels'))
assert box(idle, 110, 134, 142, 194) != box(stand, 110, 134, 142, 194) != box(raised, 110, 134, 142, 194)
white = lambda image, x0, y0, x1, y1: sum(r > 200 and g > 200 and b > 200 for r, g, b in box(image, x0, y0, x1, y1))
assert white(idle, 24, 34, 112, 44) > 40 and white(idle, 24, 106, 112, 116) == 0
assert white(labels, 24, 34, 112, 44) == 0
assert white(labels, 32, 72, 96, 82) > 40 and white(labels, 40, 84, 88, 94) > 20 and white(labels, 24, 106, 112, 116) > 40
print('OK: qualified shooter stands up, raises his arm and the arcade labels appear')
