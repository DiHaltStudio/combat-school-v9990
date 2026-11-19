#!/usr/bin/env python3
from pathlib import Path
p=Path('build/step7/visual-test')
x1,x2,w1,w2,c1,c2,before,after,attack,cpu1,cpu2=map(int,(p/'walk.txt').read_text().split())
assert x2>x1 and cpu2<cpu1 and min(w1,w2,c1,c2)>0 and before==after and attack>0,(x1,x2,w1,w2,c1,c2,before,after,attack,cpu1,cpu2)
def screen(name):
 raw=(p/f'{name}-vram.bin').read_bytes();r=(p/f'{name}-regs.bin').read_bytes();v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:];return v[(r[18]&1)*32768:][:27136]
def pixel(v,x,y):
 b=v[y*128+x//2];return b>>4 if x%2==0 else b&15
one,two=screen('walk1'),screen('walk2')
# Compare the actor in its own coordinates, not its changing screen position.
a=[pixel(one,x1+x,90+y) for y in range(64) for x in range(48)]
b=[pixel(two,x2+x,90+y) for y in range(64) for x in range(48)]
assert a!=b,'walking did not change the visible player pose'
ca=[pixel(one,cpu1+x,90+y) for y in range(64) for x in range(48)]
cb=[pixel(two,cpu2+x,90+y) for y in range(64) for x in range(48)]
assert ca!=cb,'walking did not change the visible instructor pose'
print('OK: both walking poses change; kicking prevents sliding')
