#!/usr/bin/env python3
"""Check both cameras show continuous terrain at each river boundary."""
from pathlib import Path
from PIL import Image
root=Path('build/step3/shore-test')
def water(colour):
    r,g,b=colour
    return g>100 and b>100 and g>r*1.5 and b>r*1.4
def water_at(im,x,y):
    # The arcade river has dark vertical streaks: use a small majority.
    return sum(water(im.getpixel((x+d,y))) for d in range(-4,5))>=5
for name,top,bottom in [('entry-before',True,False),('entry-after',True,False),
                         ('exit-before',False,True),('exit-after',False,True)]:
    im=Image.open(root/f'{name}.png').convert('RGB')
    for x in (50,178):
        assert water_at(im,x,30)==top, (name,x,'top')
        assert water_at(im,x,180)==bottom, (name,x,'bottom')
im=Image.open(root/'finish-approach.png').convert('RGB')
assert any(sum(1 for x in range(31,151) if min(im.getpixel((x,y)))>210)>15 for y in range(90,130)), 'missing finish line'
print('OK: both cameras show continuous shores and the finish line')
