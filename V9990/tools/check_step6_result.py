#!/usr/bin/env python3
import sys
from pathlib import Path
p=Path(sys.argv[1]); hits=int(sys.argv[2])
a=list(map(int,(p/'result.txt').read_text().split()))
bonus=min(5,max(0,hits-32))
points=(0,1000,2000,4000,6000,8000)[bonus]
assert a==[1,2 if hits>=32 else 3,18 if hits>=32 else 17,hits,0,bonus,points,int(hits>=32),65500+(points if hits>=32 else 0),int(hits>=32)],a
if hits>=32:
 def screen(name):
  v=(p/(name+'-vram.bin')).read_bytes();reg=(p/(name+'-regs.bin')).read_bytes()
  m=bytearray(len(v));m[::2]=v[:0x40000];m[1::2]=v[0x40000:]
  start=(reg[18]&1)*32768
  return bytes(m[start:start+27136])
 base=Path('build/demo/progress.bin').read_bytes()[7*32768:7*32768+27136]
 bonus_data=Path('build/demo/step6-bonus-compact.bin').read_bytes()
 bonus_screen=bytearray(bonus_data[:27136])
 y=(197,181,165,149,133,117)[bonus]
 patch=bonus_data[27136+104*bonus:27136+104*(bonus+1)]   # 8 rows x 13 bytes
 for row in range(8):bonus_screen[(y+row)*128+104:(y+row)*128+117]=patch[row*13:row*13+13]
 assert screen('bonus')==bytes(bonus_screen)
 scene=Path('build/demo/step6-interlude.bin').read_bytes()
 assert screen('interlude')==scene[:27136]
 other=bytearray(scene[:27136])
 patch=scene[27136+1248:27136+2496]
 for row in range(52):other[(106+row)*128+24:(106+row)*128+48]=patch[row*24:(row+1)*24]
 assert screen('interlude-other')==bytes(other)
 on=bytearray(base)
 for y0,y1 in ((32,60),(62,90),(92,120),(122,150),(152,180),(182,210)):
  for y in range(y0,y1+1):
   for x in range(16,32,2):on[y*128+x//2]=0x99
 assert set((screen('map'),screen('map-other')))=={base,bytes(on)}
print('OK: Step 6',hits,'hits,', 'six-step map' if hits>=32 else 'failed')
