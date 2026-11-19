#!/usr/bin/env python3
"""Verify both outcomes and the two VRAM pages of the five-step map."""
import sys
from pathlib import Path
p=Path(sys.argv[1]); win=int(sys.argv[2])
result=list(map(int,(p/'step5-result.txt').read_text().split()))
expected=[1,1,1,1 if win else 2,3 if win else 0,4000 if win else 0,33,16,0 if win else 4000,0 if win else 3]
assert result==expected,(result,expected)
def screen(name):
    v=(p/(name+'-vram.bin')).read_bytes()
    regs=(p/(name+'-regs.bin')).read_bytes()
    logical=bytearray(len(v));logical[::2]=v[:0x40000];logical[1::2]=v[0x40000:]
    start=(regs[18]&1)*32768
    return bytes(logical[start:start+27136])
# The body and arms must come from one complete picture: the arcade victory
# image, or the overhead picture with the CPU-win patch. Rows 88..157 lie
# below the STOP text and above the names.
result_screen=screen('result5')
reference=Path('build/step5/victory-reference.bin' if win else 'build/step5/cpuwin-reference.bin').read_bytes()
for y in range(88,158):
    assert result_screen[y*128:(y+1)*128]==reference[y*128:(y+1)*128], ('broken result pose',win,y)
base=Path('build/demo/progress.bin').read_bytes()[7*32768:7*32768+27136]
on=bytearray(base)
for y0,y1 in ((62,90),(92,120),(122,150),(152,180),(182,210)):
    for y in range(y0,y1+1):
        for x in range(16,32,2):on[y*128+x//2]=0x99
assert set((screen('map5'),screen('map5-other'))) == {base,bytes(on)}
print('OK: Step 5', 'won' if win else 'lost', 'bonus and five blinking map squares')
