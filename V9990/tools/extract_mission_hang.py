#!/usr/bin/env python3
"""Extract arcade hanging poses from a RAM-assisted mission state probe."""
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

with ZipFile('../ARCADE/original/combatsc.zip') as rom:
    even, odd, prom = (rom.read(n) for n in ('611g11.rom','611g12.rom','611g10.h6'))
gfx=bytearray(len(even)*2);gfx[::2],gfx[1::2]=even,odd
for frame, selected, name in ((6104,{71,72,73,69,70},'hang1'),(6124,{74,75,76,84,85},'hang2')):
    root=Path(f'build/mission/hang-probe/frame-{frame:04d}')
    pal=(root/'palette.bin').read_bytes()
    data=(root/'videoram1.bin').read_bytes()[0x1800:0x1d00]
    entries=[]
    for i in range(64):
        n,bank,sy,sx,attr=data[i*5:i*5+5]
        if n not in selected or bank!=3:continue
        typ=attr&14;w,h={0:(2,2),8:(4,4)}[typ]
        tile=(((n+((bank&3)<<8)+((attr&0xc0)<<4))<<2)+((bank>>2)&3))&~3
        entries.append((sx,sy,tile,w,h,attr,bank))
    assert len(entries)==5,entries
    minx=min(e[0] for e in entries);miny=min(e[1] for e in entries)
    img=Image.new('RGBA',(64,80))
    for sx,sy,n,w,h,attr,bank in entries:
        for ty in range(h):
            for tx in range(w):
                ex=w-1-tx if attr&16 else tx;ey=h-1-ty if attr&32 else ty
                tile=n+(0,1,4,5)[ex]+(0,2,8,10)[ey]
                for y in range(8):
                    for x in range(8):
                        px=7-x if attr&16 else x;py=7-y if attr&32 else y
                        b=gfx[tile*32+py*4+px//2];pen=b>>4 if px%2==0 else b&15
                        index=prom[(bank>>4)*16+pen]&15
                        if not index:continue
                        k=64+index;c=pal[k*2]|pal[k*2+1]<<8
                        rgb=tuple((((c>>s)&31)<<3)|(((c>>s)&31)>>2) for s in (0,5,10))
                        xx=sx-minx+tx*8+x;yy=sy-miny+ty*8+y
                        if xx<64 and yy<80:img.putpixel((xx,yy),(*rgb,255))
    img.save(f'assets/mission/{name}.png');print(name,img.getbbox())
