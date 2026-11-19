#!/usr/bin/env python3
"""Verify damage cells and their separators against live V9990 VRAM."""
from pathlib import Path
p=Path('build/step7/visual-test')
def screen(name):
 raw=(p/f'{name}-vram.bin').read_bytes();regs=(p/f'{name}-regs.bin').read_bytes()
 v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
 return v[(regs[18]&1)*32768:][:27136]
def pixel(buf,x,y):
 b=buf[y*128+x//2];return b>>4 if x%2==0 else b&15
empty,one,two=map(screen,('empty','one','two'))
for x0,width,colour in ((97,7,9),(151,8,3)):
 for y in range(45,53):
  for x in range(x0,x0+width):
   assert pixel(one,x,y)==colour and pixel(two,x,y)==colour and pixel(empty,x,y)!=colour,(x,y)
for x0,colour in ((89,9),(160,3)):
 for y in range(45,53):
  for x in range(x0,x0+7):
   assert pixel(two,x,y)==colour and pixel(one,x,y)!=colour,(x,y)
for x in (88,96,104,150,159,167):
 for y in range(45,53):
  assert pixel(two,x,y)==pixel(empty,x,y),(x,y)
print('OK: each hit fills one complete orange/violet cell and preserves separators')
