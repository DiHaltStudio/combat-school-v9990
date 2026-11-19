#!/usr/bin/env python3
"""Compare the visible player with both captured orientations in VRAM."""
from pathlib import Path
p=Path('build/mission/facing-test');atlas=Path('build/mission/atlas-reference.bin').read_bytes()
def pixel(data,x,y):
    v=data[y*128+x//2]
    return v>>4 if x%2==0 else v&15
for direction in (0,1):
    head=[x for x in range(64) if pixel(atlas,64+x,64*direction+20)]
    kick=[x for x in range(64) if pixel(atlas,64+x,64*direction+22)]
    center=sum(head)/len(head)
    # Independently establish the kick direction from its silhouette. This
    # catches reversed source captures even if the renderer copies them exactly.
    assert ((max(kick)-center)>(center-min(kick)))==(direction==0),(direction,head,kick)
for name,direction,kick in (('left',1,False),('left-kick',1,True),('right',0,False),('right-kick',0,True)):
    xpos,facing,timer=map(int,(p/(name+'.txt')).read_text().split())
    assert facing==direction and (timer>0)==kick,(name,xpos,facing,timer)
    raw=(p/(name+'-vram.bin')).read_bytes();regs=(p/(name+'-regs.bin')).read_bytes()
    memory=bytearray(len(raw));memory[::2]=raw[:0x40000];memory[1::2]=raw[0x40000:]
    screen=memory[(regs[18]&1)*32768:];checked=0
    # Both kicking and neutral frames must face the direction of movement.
    sx=(64 if kick else 0);sy=64*direction
    for y in range(64):
        for x in range(64):
            colour=pixel(atlas,sx+x,sy+y)
            if colour:
                assert pixel(screen,xpos+x,104+y)==colour,(name,x,y,colour,pixel(screen,xpos+x,104+y))
                checked+=1
    assert checked>100,(name,checked)
    print(f'OK: {name} uses the proper direction and carpet position')
