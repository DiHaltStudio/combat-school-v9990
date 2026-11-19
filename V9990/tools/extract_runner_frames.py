#!/usr/bin/env python3
"""Decode player-coloured arcade sprite entries from captured video RAM.
Uses the second live sprite page.
"""
from pathlib import Path
import sys
from zipfile import ZipFile
from PIL import Image
p=Path(sys.argv[1] if len(sys.argv)>1 else 'build/mame-button1');out=Path(sys.argv[2] if len(sys.argv)>2 else 'build/runner-run');out.mkdir(parents=True,exist_ok=True)
with ZipFile(str(Path(__file__).resolve().parents[2] / 'ARCADE' / 'original' / 'combatsc.zip')) as z:
 a,b,prom=[z.read(x) for x in ('611g11.rom','611g12.rom','611g10.h6')]
gfx=bytearray(len(a)*2);gfx[::2]=a;gfx[1::2]=b
for capture in sorted(p.glob('frame-*')):
 frame=int(capture.name.split('-')[1])
 d=(p/f'frame-{frame:04d}'/'videoram1.bin').read_bytes()[0x1800:0x1d00];pal=(p/f'frame-{frame:04d}'/'palette.bin').read_bytes(); entries=[]
 for i in range(64):
  num,bank,sy,sx,attr=d[i*5:i*5+5];sx-=256 if attr&1 else 0;sy-=256 if sy>=240 else 0
  if bank>>4!=1 or not (40<=sx<=150 and 25<=sy<=140):continue
  n=((num+((bank&3)<<8)+((attr&0xc0)<<4))<<2)+((bank>>2)&3)
  typ=attr&14;w,h={6:(1,1),4:(1,2),2:(2,1),0:(2,2),8:(4,4)}.get(typ,(1,1));n &= ~(2 if typ==4 else 1 if typ==2 else 3 if typ in (0,8) else 0)
  entries.append((sx,sy,n,w,h,attr,bank))
 if not entries:continue
 minx=min(e[0] for e in entries);miny=min(e[1] for e in entries)
 img=Image.new('RGBA',(64,64))
 for sx,sy,n,w,h,attr,bank in entries:
  for ty in range(h):
   for tx in range(w):
    ex=w-1-tx if attr&16 else tx;ey=h-1-ty if attr&32 else ty
    tile=n+[0,1,4,5][ex]+[0,2,8,10][ey]
    for y in range(8):
     for x in range(8):
      px=7-x if attr&16 else x; py=7-y if attr&32 else y
      by=gfx[tile*32+py*4+px//2];pen=by>>4 if px%2==0 else by&15
      lookup=prom[((bank>>4)*16)+pen]&15
      if lookup==0:continue
      i=64+lookup;c=pal[2*i]|pal[2*i+1]<<8
      rgb=tuple((((c>>s)&31)<<3)|(((c>>s)&31)>>2) for s in (0,5,10))
      xx=sx-minx+tx*8+x;yy=sy-miny+ty*8+y
      if 0<=xx<64 and 0<=yy<64:img.putpixel((xx,yy),(*rgb,255))
 img.save(out/f'{frame}.png')
