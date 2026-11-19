"""Validate circular framebuffer against immutable background and sprite atlas."""
from pathlib import Path
import struct
from PIL import Image
p=Path('build/mission/ring-test')
course=Path('build/mission/course-reference.bin').read_bytes()
width=Image.open('build/mission/complete-course-reference.png').width

def pixel(data,x,y,w=256):
 b=data[y*(w//2)+x//2]
 return b>>4 if x%2==0 else b&15

timing=[list(map(float,l.split())) for l in (p/'timing.txt').read_text().splitlines()]
deltas=[b[1]-a[1] for a,b in zip(timing[4:599],timing[5:600])]
assert max(deltas)<.025, max(deltas)
assert timing[239][2]==timing[4][2]-235, (timing[239],timing[4])
assert all(t[2]==864 for t in timing[479:600]), timing[-1]
for n in (10,80,160,240,320,400,480,600,*range(610,861,10)):
 raw=(p/f'{n}-vram.bin').read_bytes();v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
 regs=(p/f'{n}-regs.bin').read_bytes();ram=(p/f'{n}-ram.bin').read_bytes()
 page=regs[18]&1
 cam=struct.unpack_from('<H',ram,0x222+2*page)[0]
 assert regs[17]==cam//256,(n,regs[17],cam)
 assert regs[19]+8*regs[20]==cam%256,(n,regs[19:21],cam)
 count=ram[0x220+page]
 rects=[struct.unpack_from('<HBHH',ram,0x300+page*256+7*i) for i in range(count)]
 errors=[]
 for y in range(32,212):
  for x in range(256):
   world=cam+x
   if any(wx<=world<wx+w and yy<=y<yy+h for wx,yy,w,h in rects):continue
   actual=pixel(v,cam%256+x,page*256+cam//256+y)
   expected=pixel(course,world,y,width)
   # Static final actors persist in each ring page; they are not dirty.
   if 136<=y<200:
    for origin,sx in (((117,128),) if ram[0x181] else ((133,0),(117,128))):
     if 0<=world-origin<64:
      c=pixel(v,sx+world-origin,656+y-136)
      if c:expected=c
   if actual!=expected:errors.append((x,y,actual,expected))
 assert not errors,(n,len(errors),errors[:8])
 # HUD: the damage strip remains fixed at screen x=0, y=16 despite scroll,
 # only in the final fight (c981); before it the whole band stays black.
 health=ram[0x56]
 for y in range(16 if ram[0x181] else 32):
  for x in range(256):
   if not ram[0x181]:
    world=cam+x
    if not any(wx<=world<wx+w and yy<=y<yy+h for wx,yy,w,h in rects):
     assert pixel(v,cam%256+x,page*256+cam//256+y)==0,(n,'band',x,y)
    continue
   sourcey=2448+(8-ram[0x186])*8+y-8 if ram[0x181] and x<112 and y>=8 else 2304+(8-health)*16+y
   assert pixel(v,cam%256+x,page*256+cam//256+16+y)==pixel(v,x,sourcey),(n,'HUD',x,y)
 if not ram[0xdd]:continue
 # Final-room artwork is compared against decoded atlas, including overlap.
 if n>=780:
  checked=0
  for y in range(64):
   for world in range(max(117,cam),min(197,cam+256)):
    colour=0
    for origin,sx in (((117,128),) if ram[0x181] else ((133,0),(117,128))):
     if 0<=world-origin<64:
      c=pixel(v,sx+world-origin,656+y)
      if c:colour=c
    if colour:
     assert pixel(v,world-cam+cam%256,page*256+cam//256+136+y)==colour,('final actor',world,y)
     checked+=1
  if n==780:assert checked>300,checked
 # Fully opaque hanging pixels must survive the crop and ring seam.
 pose=(0 if ram[9] else 128)+ram[0xde]*8
 for y in range(80):
  for x in range(64):
   c=pixel(v,pose+x,512+y)
   if c:assert pixel(v,cam%256+ram[1]+x,page*256+cam//256+81+y)==c,(n,'player',x,y)
print(f'OK: {len(deltas)} loaded scrolling intervals, max {max(deltas)*1000:.2f} ms; both directions, background, fixed HUD and complete player verified')
