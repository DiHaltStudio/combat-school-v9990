from pathlib import Path
import struct
from PIL import Image
p=Path('build/mission/door-sweep-test')
course=Path('build/mission/course-reference.bin').read_bytes()
width=Image.open('build/mission/complete-course-reference.png').width
def pixel(data,x,y,w=256):
 b=data[y*(w//2)+x//2];return b>>4 if x%2==0 else b&15
for i in range(76):
 raw=(p/f'{i}-vram.bin').read_bytes();v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
 r=(p/f'{i}-regs.bin').read_bytes();ram=(p/f'{i}-ram.bin').read_bytes();page=r[18]&1
 cam=struct.unpack_from('<H',ram,0x222+page*2)[0]
 for y in range(70,205):
  for world in range(1354,1379):
   actual=pixel(v,(cam%256)+world-cam,page*256+cam//256+y)
   assert actual==pixel(course,world,y,width),(i,world,y,actual)
print('OK: 76 positions in both directions, on the ground and airborne; full doorway stays in front')
