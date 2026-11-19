#!/usr/bin/env python3
from pathlib import Path
p=Path('build/step7/visual-test');atlas=Path('build/step7/atlas.bin').read_bytes()
def pixel(data,x,y):
 b=data[y*128+x//2];return b>>4 if x%2==0 else b&15
def screen(name):
 raw=(p/f'{name}-vram.bin').read_bytes();r=(p/f'{name}-regs.bin').read_bytes();v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:];return v[(r[18]&1)*32768:]
for name,source_x,dest_x in (('instructor-down',64,120),('player-down',192,70)):
 v=screen(name);checked=0
 for y in range(16):
  for x in range(64):
   colour=pixel(atlas,source_x+x,320+y)
   if colour:
    assert pixel(v,dest_x+x,138+y)==colour,(name,x,y,colour,pixel(v,dest_x+x,138+y))
    checked+=1
 assert checked>100,(name,checked)
 print(f'OK: {name} sprite lies on the platform')
