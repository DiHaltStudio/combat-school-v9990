#!/usr/bin/env python3
"""YOUR TITLE screen (src/step7_visual.asm ending_rank_arrow): the rank chosen
for the score, the 1P arrow on that rank's OVER row (x 8) and nowhere else,
and no score at the bottom (the arcade's P1 (NICK) and points were removed)."""
from pathlib import Path
import re
import sys
score=int(sys.argv[1]);p=Path(sys.argv[2])
rank,lo,mid,hi=map(int,(p/'rank.txt').read_text().split())
expected=sum(score>x for x in (200000,220000,240000,260000))
assert rank==expected and lo+(mid<<8)+(hi<<16)==score,(score,rank,expected,lo,mid,hi)
raw=(p/'vram.bin').read_bytes();regs=(p/'regs.bin').read_bytes();v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:];v=v[(regs[18]&1)*32768:]
arrow=Path('build/step7/rank-arrow.bin').read_bytes()
rows=[int(r) for r in re.findall(r'\d+',Path('build/step7/rank-rows.inc').read_text())]
def arrow_at(y):
 return all(v[(y+r)*128+4:(y+r)*128+16]==arrow[r*12:(r+1)*12] for r in range(8))
for index,y in enumerate(rows):
 assert arrow_at(y)==(index==rank),(score,index,y)
bottom=v[200*128:212*128]
assert not any(bottom),(score,'something drawn below the ranks')
print(f'OK: {score} points selects rank {rank}, arrow on its row and no score below')
