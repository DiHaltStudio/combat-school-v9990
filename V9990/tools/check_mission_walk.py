#!/usr/bin/env python3
"""Check all four walking phases are rendered from captured sprites."""
from pathlib import Path
p=Path('build/mission/walk-test')
extra=Path('build/mission/extra-reference.bin').read_bytes()
def pixel(data,x,y):
    v=data[y*128+x//2]
    return v>>4 if x%2==0 else v&15
seen=[]
for phase in range(4):
    raw=(p/f'{phase}-vram.bin').read_bytes();regs=(p/f'{phase}-regs.bin').read_bytes()
    memory=bytearray(len(raw));memory[::2]=raw[:0x40000];memory[1::2]=raw[0x40000:]
    screen=memory[(regs[18]&1)*32768:]
    matches=[]
    for candidate in range(4):
        total=good=0
        for y in range(64):
            for x in range(64):
                c=pixel(extra,candidate*64+x,128+y)
                if c:
                    total+=1;good+=pixel(screen,96+x,104+y)==c
        matches.append(good/total)
    best=max(range(4),key=lambda i:matches[i]);seen.append(best)
    assert matches[best]>.95,(phase,matches)
assert len(set(seen))>=3,seen
print(f'OK: walking cycles through captured arcade poses {seen}')
