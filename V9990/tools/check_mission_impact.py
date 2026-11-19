#!/usr/bin/env python3
"""Both types of real collision must draw the shared flash at the hit."""
from pathlib import Path
p=Path('build/mission/impact-test')
atlas=Path('build/mission/atlas-reference.bin').read_bytes()
def pixel(data,x,y):
    b=data[y*128+x//2]
    return b>>4 if x%2==0 else b&15
for name,source in [('enemy-hit',96),('player-hit',112)]:
    timer,tile,x=map(int,(p/f'{name}.txt').read_text().split())
    assert timer>0 and tile==source,(name,timer,tile)
    raw=(p/f'{name}-vram.bin').read_bytes()
    regs=(p/f'{name}-regs.bin').read_bytes()
    memory=bytearray(len(raw));memory[::2]=raw[:0x40000];memory[1::2]=raw[0x40000:]
    screen=memory[(regs[18]&1)*32768:]
    opaque=0
    for y in range(16):
        for dx in range(16):
            expected=pixel(atlas,source+dx,488+y)
            if expected:
                opaque+=1
                assert pixel(screen,x+dx,128+y)==expected,(name,x+dx,y,expected,pixel(screen,x+dx,128+y))
    assert opaque>50
    print(f'OK: {name} draws the expected impact graphic at x={x}')
