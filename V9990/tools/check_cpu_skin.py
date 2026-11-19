#!/usr/bin/env python3
"""Ensure CPU skin retains the same encoded palette as the player's identical skin colours."""
from collections import defaultdict
from pathlib import Path
from PIL import Image
p=Path('build/demo')
a=(p/'runner.bin').read_bytes(); b=(p/'cpu.bin').read_bytes()
player=Image.open('build/runner-run/1102.png').crop((0,0,32,48)).convert('RGBA')
cpu=Image.open('build/cpu-reference/1155.png').crop((0,0,32,48)).convert('RGBA')
positions=defaultdict(list)
def get(data,x,y):
 byte=data[y*16+x//2]
 return byte>>4 if x%2==0 else byte&15
for source,data in ((player,a),(cpu,b)):
 for y in range(48):
  for x in range(32):
   rgba=source.getpixel((x,y))
   if rgba[:3] in ((206,115,107),(214,165,148)) and rgba[3]:positions[rgba[:3]].append(get(data,x,y))
assert all(len(set(indices))==1 and len(indices)>=2 for indices in positions.values())
assert len(positions)==2
pal=(p/'palette.bin').read_bytes()
for rgb,indices in positions.items():
 idx=indices[0];r,g,blue=pal[idx*3:idx*3+3]
 assert r>=g and r>=blue, f'skin colour became green: {rgb}'
print('OK: CPU and player share the same two skin palette entries')
