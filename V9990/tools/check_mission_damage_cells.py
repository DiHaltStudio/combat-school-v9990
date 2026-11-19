#!/usr/bin/env python3
"""Compare every damage state against the original HUD and its separators."""
from pathlib import Path
p=Path('build/mission/damage-test')
atlas=Path('build/mission/atlas-reference.bin').read_bytes()
colour=int(Path('build/mission/damage-colour.txt').read_text())
def pixel(data,x,y):
    n=data[y*128+x//2]
    return n>>4 if x%2==0 else n&15
for damage in range(9):
    raw=(p/f'damage-{damage}-vram.bin').read_bytes();regs=(p/f'damage-{damage}-regs.bin').read_bytes()
    memory=bytearray(len(raw));memory[::2]=raw[:0x40000];memory[1::2]=raw[0x40000:]
    screen=memory[(regs[18]&1)*32768:]
    for y in range(16,32):
        for x in range(256):
            in_cell=24<=y<32 and ((151<=x<159 and damage>=1) or (160<=x<215 and (x-160)%8<7 and (x-160)//8<damage-1))
            expected=colour if in_cell else pixel(atlas,x,448+y-16)
            assert pixel(screen,x,y)==expected,(damage,x,y,expected,pixel(screen,x,y))
    print(f'OK: {damage} filled damage cells preserve the HUD and separators')
