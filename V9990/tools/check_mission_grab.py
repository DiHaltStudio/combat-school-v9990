#!/usr/bin/env python3
"""Check the captured held/fallen poses and temporary loss of control."""
from pathlib import Path
import os
p=Path(os.environ['MISSION_TEST_OUT'])
facing=int(os.environ['MISSION_GRAB_FACING'])
def state(name):return [int(x) for x in (p/f'{name}.txt').read_text().split()]
held,fallen,recovered,movement=(state(n) for n in ('held','fallen','recovered','movement'))
assert 31<held[0]<=48 and 0<fallen[0]<=20 and recovered[0]==0
assert (held[1],held[3],held[4])==(fallen[1],fallen[3],fallen[4]) and held[3]==0,(held,fallen)
assert movement[4]==recovered[4] and movement[3]==0,(recovered,movement)
atlas=Path('build/mission/atlas-reference.bin').read_bytes()
colour=int(Path('build/mission/damage-colour.txt').read_text())
def pixel(data,x,y):
    b=data[y*128+x//2]
    return b>>4 if x%2==0 else b&15
filled=[]
for name,sx in [('held',128),('fallen',192),('movement',192)]:
    raw=(p/f'{name}-vram.bin').read_bytes();regs=(p/f'{name}-regs.bin').read_bytes()
    memory=bytearray(len(raw));memory[::2]=raw[:0x40000];memory[1::2]=raw[0x40000:]
    screen=memory[(regs[18]&1)*32768:]
    filled.append(sum(pixel(screen,x,27)==colour for x in [154,163,171,179,187,195,203,211]))
    count=0
    for y in range(64):
        for x in range(64):
            c=pixel(atlas,sx+x,(256 if facing else 192)+y)
            if c:
                count+=1
                assert pixel(screen,96+x,104+y)==c,(name,x,y,c,pixel(screen,96+x,104+y))
    assert count>50,(name,count)
    print(f'OK: {name} uses the captured arcade pose')
assert filled==[8,8,8],filled
print('OK: fatal knife hit fills all damage cells throughout the fall')
print('OK: one hit ends the mission and controls stay disabled after the fall')
