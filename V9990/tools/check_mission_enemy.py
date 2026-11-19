#!/usr/bin/env python3
from pathlib import Path
p=Path('build/mission/enemy-test')
def state(name):return list(map(int,(p/(name+'.txt')).read_text().split()))
hit=state('hit');wrong=state('wrong-facing');distant=state('distant')
contact=state('contact');held=state('contact-held');air=state('air-hit')
gameover=state('game-over');restarted=state('restarted')
assert hit[0] in (2,3,4) and hit[1:3]==[8,500],hit
assert wrong[0]==1 and wrong[2]==0,wrong
assert distant[0]==1 and distant[2]==0,distant
assert contact[1]==held[1]==0 and contact[2]==held[2]==0,(contact,held)
assert air[0] in (2,3,4) and air[1:3]==[8,500],air
assert gameover[1]==0 and restarted[1:3]==[8,0] and restarted[0] in (0,1),(gameover,restarted)
raw=(p/'hit-vram.bin').read_bytes();regs=(p/'hit-regs.bin').read_bytes()
v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
screen=v[(regs[18]&1)*32768:];atlas=Path('build/mission/atlas-reference.bin').read_bytes()
def pixel(data,x,y):
    n=data[y*128+x//2]
    return n>>4 if x%2==0 else n&15
enemy_x=hit[4];checked=0
for y in range(64):
    for x in range(64):
        if enemy_x+x>=96:continue  # player may cover this part of the enemy
        c=pixel(atlas,128+x,128+y)
        if c:
            assert pixel(screen,enemy_x+x,104+y)==c,('enemy sprite',x,y)
            checked+=1
assert checked>30,checked
for y in range(8):
    actual=screen[y*128+4:y*128+36]
    expected=atlas[(480+y)*128+32:(480+y)*128+64]
    assert actual==expected,('score',y)
raw=(p/'contact-vram.bin').read_bytes();regs=(p/'contact-regs.bin').read_bytes()
v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
screen=v[(regs[18]&1)*32768:];colour=int(Path('build/mission/damage-colour.txt').read_text())
for y in range(24,32):
    for x in range(151,159):assert pixel(screen,x,y)==colour,('damage cell',x,y)
    for x in (159,167):assert pixel(screen,x,y)==pixel(atlas,x,448+y-16),('cell separator',x,y)
print('OK: enemy sprite, score, hit range, recovery, aerial hit, game over and restart')
