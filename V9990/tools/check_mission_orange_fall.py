#!/usr/bin/env python3
"""Verify original orange poses, short transition, and persistent body."""
from pathlib import Path
import os
p=Path(os.environ['MISSION_TEST_OUT'])
left=int(os.environ['MISSION_ORANGE_FACING'])
extra=Path('build/mission/extra-reference.bin').read_bytes()
def pixel(data,x,y):
    v=data[y*128+x//2]
    return v>>4 if x%2==0 else v&15
for name,sx,sy in [('hit',128,64*left),('knee',192,64*left),('hands',128*left,256),('down',64+128*left,256)]:
    raw=(p/f'{name}-vram.bin').read_bytes();regs=(p/f'{name}-regs.bin').read_bytes()
    v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
    screen=v[(regs[18]&1)*32768:]
    total=good=0
    for y in range(64):
        for x in range(64):
            c=pixel(extra,sx+x,sy+y)
            if c:
                total+=1;good+=pixel(screen,40+x,104+y)==c
    assert total>40 and good/total>.95,(name,total,good)
    print(f'OK: {name} uses the captured orange arcade pose')
frames=int((p/'timing.txt').read_text())
assert frames<=60 and int((p/'persist.txt').read_text())==4,frames
print(f'OK: fall finishes in {frames} display frames and the body remains visible')
