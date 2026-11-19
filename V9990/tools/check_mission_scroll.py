#!/usr/bin/env python3
"""Verify VRAM copies against the captured room at strip boundaries."""
from pathlib import Path
from PIL import Image, ImageChops
p=Path('build/mission/scroll-test')
width=Image.open('assets/mission/course-expanded.png').width
original=Image.open('assets/mission/course-to-crates.png').convert('RGB')
expanded=Image.open('assets/mission/course-expanded.png').convert('RGB')
assert ImageChops.difference(original, expanded.crop((width-original.width,0,width,212))).getbbox() is None, 'the original doorway and crates must remain intact'
source=Path('build/mission/course-reference.bin').read_bytes()
def pixel(data,stride,x,y):
    v=data[y*stride+x//2]
    return v>>4 if x%2==0 else v&15
for camera in (0,1,255,256,552,767,768,1023,1024,1279,1280,1535,1536):
    raw=(p/f'scroll-{camera}-vram.bin').read_bytes();regs=(p/f'scroll-{camera}-regs.bin').read_bytes()
    memory=bytearray(len(raw));memory[::2]=raw[:0x40000];memory[1::2]=raw[0x40000:]
    screen=memory[(regs[18]&1)*32768:]
    for y in range(212):
        for x in range(256):
            if y<32:continue  # fixed score and damage display
            if 96<=x<160 and 104<=y<200:continue
            assert pixel(screen,128,x,y)==pixel(source,width//2,camera+x,y),(camera,x,y)
    print(f'OK: room window at {camera} matches the captured background')
left,left_player,right,right_player=map(int,(p/'movement.txt').read_text().split())
assert left<256 and right>left and 95<=left_player<=97 and 95<=right_player<=97,(left,left_player,right,right_player)
print('OK: moving in either direction scrolls the room and keeps the player centred')
