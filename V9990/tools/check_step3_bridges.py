#!/usr/bin/env python3
"""Validate stepping off, blocking the deck, jumping and exiting each bridge."""
from pathlib import Path
p=Path('build/step3/bridge-test/result.txt')
values=list(map(int,p.read_text().split()))
assert len(values)==24, values
for index in range(3):
    water,fall,x,blocked,x_blocked,jump,out,out_fall=values[index*8:index*8+8]
    # Arcade map: the deck is left of the water, ending at these x.
    deck_right=(72,80,48)[index]
    assert water==1 and fall==0 and x+8>=deck_right, (index,values)
    assert blocked==1 and x_blocked+8>=deck_right and x_blocked<x, (index,values)
    assert jump==0 and out==0 and out_fall==0, (index,values)
cpu=list(map(int,Path('build/step3/bridge-cpu.txt').read_text().split()))
assert cpu==[1,0,0,0]*3, cpu
print('OK: player and CPU wade, deck blocks entry, and shores permit exit on three bridges')
