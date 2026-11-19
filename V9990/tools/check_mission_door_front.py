"""Doorway walls (world 1354..1361 and 1371..1378 at the pink room, 477..500
at the brick room) drawn over the actors, clipped at both screen sides, with
the rest of the background intact."""
from pathlib import Path
import struct
from PIL import Image
p=Path('build/mission/door-front-test')
course=Path('build/mission/course-reference.bin').read_bytes()
width=Image.open('build/mission/complete-course-reference.png').width
def pixel(data,x,y,w=256):
 b=data[y*(w//2)+x//2]
 return b>>4 if x%2==0 else b&15
covered=0
DOOR=[(1354,1379),(477,501)]
for n,expect_cam in ((1,1229),(2,1102),(3,1358),(4,1229),(5,361),(6,229),(7,495)):
 raw=(p/f'{n}-vram.bin').read_bytes();v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
 regs=(p/f'{n}-regs.bin').read_bytes();ram=(p/f'{n}-ram.bin').read_bytes()
 page=regs[18]&1
 cam=struct.unpack_from('<H',ram,0x222+2*page)[0]
 assert cam==expect_cam,(n,cam)
 count=ram[0x220+page]
 rects=[struct.unpack_from('<HBHH',ram,0x300+page*256+7*i) for i in range(count)]
 checked=0
 for y in range(32,212):
  for x in range(256):
   world=cam+x
   door=any(a<=world<b for a,b in DOOR)
   if not door and any(wx<=world<wx+w and yy<=y<yy+h for wx,yy,w,h in rects):continue
   actual=pixel(v,cam%256+x,page*256+cam//256+y)
   assert actual==pixel(course,world,y,width),(n,x,y,world,'door' if door else 'background')
   checked+=door
 if n in (1,4,5):
  covered+=sum(1 for wx,yy,w,h in rects if any(wx<b and wx+w>a for a,b in DOOR))
 print(n,cam,'door pixels',checked,'dirty rects',count)
assert covered>=3,covered
print('OK: the doorway walls stay in front of the actors at both doorways, also clipped at both screen sides')
