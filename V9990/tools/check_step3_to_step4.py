#!/usr/bin/env python3
"""Validate the actual V9990 screens and carried data through Step 4."""
import sys
from pathlib import Path
from PIL import Image,ImageChops
p=Path(sys.argv[1]);remaining=int(sys.argv[2])
seen8,seen9,seen10,seen_map,stage,bonus,seconds,score,start,end,pre_score,race_points,shots,bank,bank_stage=map(int,(p/'result.txt').read_text().split())
expected_bonus=min(remaining//2,5)
assert (seen8,seen9,seen10,seen_map,stage)==(1,1,1,1,11)
assert bonus==expected_bonus and 33+bonus<=seconds<=34+bonus
assert pre_score==6000 and race_points==(0,1000,2000,4000,6000,8000)[bonus]
assert score==pre_score+race_points and end>start
if shots != -1: assert shots>=2 and bank==82 and bank_stage==11, (shots,bank,bank_stage)

def screen(name):
 v=(p/(name+'-vram.bin')).read_bytes();regs=(p/(name+'-regs.bin')).read_bytes()
 logical=bytearray(len(v));logical[::2]=v[:0x40000];logical[1::2]=v[0x40000:]
 start=(regs[18]&1)*32768
 return bytes(logical[start:start+27136])
reference=Path('build/demo/progress.bin').read_bytes()
assert screen('bonus') == reference[bonus*32768:bonus*32768+27136]
base=bytearray(reference[7*32768:7*32768+27136])
for y0,y1 in ((122,150),(152,180),(182,210)):
 for y in range(y0,y1+1):
  for x in range(16,32,2):base[y*128+x//2]=0x99
maps=[screen('map'),screen('map-other')]
assert set(maps)=={bytes(base),reference[7*32768:7*32768+27136]}
a=Image.open(p/'animation.png').convert('RGB');b=Image.open(p/'animation-other.png').convert('RGB')
assert ImageChops.difference(a,b).getbbox() is not None
print(f'OK: {remaining}s remaining, bonus {bonus}s/{race_points}pts, three-step map and playable Step 4')
