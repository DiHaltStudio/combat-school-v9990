#!/usr/bin/env python3
from pathlib import Path
p=Path('build/step7/visual-test')
o,c,health,ce,oe,v,player,ph,pe,ve,co,po=map(int,(p/'impact.txt').read_text().split())
assert o>0 and v>0 and health==ph==7 and ce>100 and pe<70 and co<100 and po>123 and oe==ve==0,(o,c,health,ce,oe,v,player,ph,pe,ve,co,po)
def image(name):
 raw=(p/f'{name}-vram.bin').read_bytes();r=(p/f'{name}-regs.bin').read_bytes();vram=bytearray(len(raw));vram[::2]=raw[:0x40000];vram[1::2]=raw[0x40000:];return vram[(r[18]&1)*32768:][:27136]
def pixel(v,x,y):
 b=v[y*128+x//2];return b>>4 if x%2==0 else b&15
orange=image('orange');violet=image('violet')
assert sum(pixel(orange,x,y)==9 for y in range(108,124) for x in range(c,c+16))>=4
assert sum(pixel(violet,x,y)==3 for y in range(108,124) for x in range(player+8,player+24))>=4
print('OK: both impacts show the correct flash and push the recipient back')
