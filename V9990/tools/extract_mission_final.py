#!/usr/bin/env python3
"""Decode final-room actors from the captured arcade sprite entries."""
from pathlib import Path
from zipfile import ZipFile
from PIL import Image
root=Path('build/mission/course-beyond-probe/frame-7923')
pal=(root/'palette.bin').read_bytes();data=(root/'videoram0.bin').read_bytes()[0x1800:]
with ZipFile('../ARCADE/original/combatsc.zip') as z:
 even,odd,prom=(z.read(x) for x in ('611g07.rom','611g08.rom','611g06.h14'))
gfx=bytearray(len(even)*2);gfx[::2]=even;gfx[1::2]=odd
for name,indices in [('chain-idle',(0,1)),('president',(2,3,4))]:
 entries=[data[i*5:i*5+5] for i in indices];minx=min(e[3] for e in entries);miny=min(e[2] for e in entries)
 im=Image.new('RGBA',(64,64))
 for number,bank,sy,sx,attr in entries:
  typ=attr&14;w,h={0:(2,2),8:(4,4)}[typ]
  base=(((number+((bank&3)<<8)+((attr&0xc0)<<4))<<2)+((bank>>2)&3))&~3
  for ty in range(h):
   for tx in range(w):
    ex=w-1-tx if attr&16 else tx;ey=h-1-ty if attr&32 else ty
    tile=base+(0,1,4,5)[ex]+(0,2,8,10)[ey]
    for y in range(8):
     for x in range(8):
      px=7-x if attr&16 else x;py=7-y if attr&32 else y
      b=gfx[tile*32+py*4+px//2];pen=b>>4 if px%2==0 else b&15
      idx=prom[(bank>>4)*16+pen]&15
      if not idx:continue
      c=pal[idx*2]|pal[idx*2+1]<<8
      rgb=tuple((((c>>v)&31)<<3)|(((c>>v)&31)>>2) for v in (0,5,10))
      xx=sx-minx+tx*8+x;yy=sy-miny+ty*8+y
      if xx<64 and yy<64:im.putpixel((xx,yy),(*rgb,255))
 im.save('assets/mission/'+name+'.png')
