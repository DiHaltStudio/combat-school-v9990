#!/usr/bin/env python3
"""Check that result labels do not occupy other sprites' bitmap rectangles."""
from pathlib import Path

def pixel(buf,x,y):
    value=buf[y*128+x//2]
    return value >> 4 if x%2==0 else value&15
shoot=Path('build/demo/shoot-atlas.bin').read_bytes()
# The target's lower eight rows contain only its vertical stand and base.
for y in range(16,24):
    for x in range(16):
        assert pixel(shoot,x,y) != 14, ('white text in target',x,y)
# Every word in the qualified message has visible letters.
for x0,x1 in ((32,56),(64,96),(104,120)):
    assert any(pixel(shoot,x,y)==14 for y in range(16,26) for x in range(x0,x1)), (x0,x1)
step3=Path('build/step3/visual-atlas.bin').read_bytes()
# Player/CPU and bonus/time labels each occupy their own eight-pixel row.
for y in (0,8,16,24):
    assert all(pixel(step3,x,y+7)==0 for x in (range(160,224) if y<16 else range(96,124))), y
step4=Path('build/step4/atlas.bin').read_bytes()
# PLAYER 1, (NICK) and YOU MADE IT at atlas y 28..37, clear of the digits
# (y 16..25) and of the grid, projectile and blasts (from y 48).
for x0,x1 in ((0,64),(64,112),(112,200)):
    assert any(pixel(step4,x,y)==9 for y in range(28,38) for x in range(x0,x1)), (x0,x1)
for y in (26,27,38,39,40,41,42,43,44,45,46,47):
    assert all(pixel(step4,x,y)==0 for x in range(200)), y
print('OK: result labels fit their atlas regions and do not overlap target graphics')
