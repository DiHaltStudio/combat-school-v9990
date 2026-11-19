#!/usr/bin/env python3
from pathlib import Path
p=Path('build/mission/two-enemies-test')
left=list(map(int,(p/'left-hit.txt').read_text().split()))
right=list(map(int,(p/'right-hit.txt').read_text().split()))
assert left[0] in (2,3,4) and left[1:]==[1,500,8],left
assert right[0] in (3,4,5) and right[1] in (2,3,4) and right[2:]==[1000,8],right
raw=(p/'score-vram.bin').read_bytes();regs=(p/'score-regs.bin').read_bytes()
v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
screen=v[(regs[18]&1)*32768:];atlas=Path('build/mission/atlas-reference.bin').read_bytes()
for y in range(8):
    assert screen[y*128+4:y*128+36]==atlas[(480+y)*128+64:(480+y)*128+96],('score',y)
print('OK: independent enemies on both sides award and display 500 + 500 points')
