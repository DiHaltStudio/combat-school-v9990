#!/usr/bin/env python3
"""Check that real jump/attack input draws the captured flying kick."""
from pathlib import Path
p=Path('build/mission/airkick-test');atlas=Path('build/mission/atlas-reference.bin').read_bytes()
def pixel(data,x,y):
    v=data[y*128+x//2]
    return v>>4 if x%2==0 else v&15
for name,direction in (('left',1),('right',0)):
    xpos,facing,attack,jump,height=map(int,(p/(name+'.txt')).read_text().split())
    assert facing==direction and 19<=attack<25 and jump>0 and height>0,(name,xpos,facing,attack,jump,height)
    raw=(p/(name+'-vram.bin')).read_bytes();regs=(p/(name+'-regs.bin')).read_bytes()
    memory=bytearray(len(raw));memory[::2]=raw[:0x40000];memory[1::2]=raw[0x40000:]
    screen=memory[(regs[18]&1)*32768:]
    points=[(x,y,pixel(atlas,192+x,64*direction+y)) for y in range(64) for x in range(64)]
    points=[(x,y,c) for x,y,c in points if c]
    assert len(points)>100,(name,len(points))
    # The CPU may be drawing the next page when memory is sampled.
    matches=[]
    for delta in range(-3,4):
        top=104-height+delta
        for dx in range(-3,4):
            left=xpos+dx
            if left<0 or left+64>256:continue
            matches.append(sum(pixel(screen,left+x,top+y)==c for x,y,c in points))
    assert max(matches)>=len(points)*0.97,(name,height,max(matches),len(points))
    print(f'OK: {name} flying kick appears during a moving jump')
