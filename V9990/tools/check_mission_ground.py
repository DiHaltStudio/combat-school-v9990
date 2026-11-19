#!/usr/bin/env python3
"""Compare rendered player pixels on the hallway, stairs and lower floor."""
from pathlib import Path
p=Path('build/mission/ground-test');atlas=Path('build/mission/atlas-reference.bin').read_bytes()
def pixel(data,x,y):
    b=data[y*128+x//2]
    return b>>4 if x%2==0 else b&15
for camera,offset in ((350,0),(180,8),(150,24),(0,32)):
    raw=(p/f'{camera}-vram.bin').read_bytes();regs=(p/f'{camera}-regs.bin').read_bytes()
    v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:];screen=v[(regs[18]&1)*32768:]
    total=good=0
    for y in range(64):
        for x in range(64):
            c=pixel(atlas,x,y)
            if c and 104+offset+y<212:
                total+=1;good+=pixel(screen,96+x,104+offset+y)==c
    assert total>50 and good/total>.95,(camera,offset,total,good)
    print(f'OK: camera {camera}, player ground offset {offset}')
camera,hp=map(int,(p/'crossing.txt').read_text().split())
assert camera<200 and hp==8,(camera,hp)
print('OK: normal movement crosses the doorway onto the stairs')
