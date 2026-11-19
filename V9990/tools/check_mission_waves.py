#!/usr/bin/env python3
"""Check one-shot cues, safe sides, terminal state, and extended score."""
from pathlib import Path
p=Path('build/mission/waves-test')
def state(name):return [int(x) for x in (p/f'{name}.txt').read_text().split()]
before,left,repeat,right,backtrack,safe,pre_dead,dead=(state(n) for n in ('before','left','no-repeat','right','backtrack','safe-side','pre-dead','dead'))
assert before[0]==0,before
assert left[0]==1 and left[1]==1,left
assert repeat[0]==1 and repeat[1:3]==[5,5],repeat
assert right[0]==2 and right[2]==1,right
assert backtrack[0]==2,backtrack
assert safe[0]==2 and safe[1:3]==[5,5],safe  # industrial zone uses explicit actors
assert dead[:4]==pre_dead[:4] and dead[1:4]==[5,5,0],(pre_dead,dead)
extra=Path('build/mission/extra-reference.bin').read_bytes()
for name,x,y in [('score2000',0,328),('score5500',192,336),('score6000',0,344)]:
    raw=(p/f'{name}-vram.bin').read_bytes();regs=(p/f'{name}-regs.bin').read_bytes()
    v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
    screen=v[(regs[18]&1)*32768:]
    for row in range(8):
        assert screen[row*128+4:row*128+36]==extra[(y+row)*128+x//2:(y+row)*128+x//2+32],(name,row)
print('OK: reinforcement cues occur once, use a safe side, stop on defeat, and display later scores')
