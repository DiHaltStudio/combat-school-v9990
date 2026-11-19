#!/usr/bin/env python3
"""Check Step 4 bonus accounting and both pages of the progress map."""
import sys
from pathlib import Path
p=Path(sys.argv[1]);hits=int(sys.argv[2])
bracket=sum(hits>=n for n in (54,56,58,60,64))
assert list(map(int,(p/'bonus4.txt').read_text().split())) == [bracket,(0,1000,2000,4000,6000,8000)[bracket],13]
def screen(name):
    v=(p/(name+'-vram.bin')).read_bytes()
    regs=(p/(name+'-regs.bin')).read_bytes()
    logical=bytearray(len(v));logical[::2]=v[:0x40000];logical[1::2]=v[0x40000:]
    start=(regs[18]&1)*32768
    return bytes(logical[start:start+27136])
reference=Path('build/demo/progress.bin').read_bytes()[7*32768:7*32768+27136]
illuminated=bytearray(reference)
for y0,y1 in ((92,120),(122,150),(152,180),(182,210)):
    for y in range(y0,y1+1):
        for x in range(16,32,2): illuminated[y*128+x//2]=0x99
assert set((screen('map4'),screen('map4-other'))) == {reference,bytes(illuminated)}
print(f'OK: {hits} hits, bonus {bracket}s, four blinking steps')
