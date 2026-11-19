from pathlib import Path
from zipfile import ZipFile
from PIL import Image
import os
project=Path(__file__).resolve().parents[1]
kind=os.environ.get('STEP7_CAPTURE','normal')
assert kind in ('normal','walk','ko','player-ko')
walk=kind=='walk'
root=project/('build/step7/'+{'normal':'mame','walk':'walk-mame','ko':'ko-mame','player-ko':'player-ko-mame'}[kind])
out=project/('build/step7/'+{'normal':'sprites','walk':'walk-sprites','ko':'ko-sprites','player-ko':'player-ko-sprites'}[kind]);out.mkdir(parents=True,exist_ok=True)
with ZipFile(project.parent/'ARCADE/original/combatsc.zip') as z:
 assets=[tuple(z.read(n) for n in group) for group in (('611g07.rom','611g08.rom','611g06.h14'),('611g11.rom','611g12.rom','611g10.h6'))]
frames=range(960,1005,4) if walk else range(1012,1121,4) if kind in ('ko','player-ko') else (1024,1050,1070,1090,1210,1230)
for frame in frames:
 p=root/f'frame-{frame:04d}';pal=(p/'palette.bin').read_bytes()
 for circ in (0,1):
  a,b,prom=assets[circ];gfx=bytearray(len(a)*2);gfx[::2]=a;gfx[1::2]=b
  data=(p/f'videoram{circ}.bin').read_bytes()[0x1800:0x1d00]; entries=[]
  for i in range(64):
   num,bank,sy,sx,attr=data[i*5:i*5+5];sx-=256 if attr&1 else 0;sy-=256 if sy>=240 else 0
   if not ((0 if kind!='normal' else 35)<=sx<=(220 if kind in ('ko','player-ko') else 200 if walk else 160) and 60<=sy<=200) or (circ==1 and bank>>4 not in ((1,2) if kind=='player-ko' else (1,))):continue
   n=((num+((bank&3)<<8)+((attr&0xc0)<<4))<<2)+((bank>>2)&3)
   typ=attr&14;w,h={6:(1,1),4:(1,2),2:(2,1),0:(2,2),8:(4,4)}.get(typ,(1,1));n &= ~(2 if typ==4 else 1 if typ==2 else 3 if typ in (0,8) else 0)
   entries.append((sx,sy,n,w,h,attr,bank))
  if not entries:continue
  minx=min(e[0] for e in entries);miny=min(e[1] for e in entries);img=Image.new('RGBA',(64,64))
  for sx,sy,n,w,h,attr,bank in entries:
   for ty in range(h):
    for tx in range(w):
     ex=w-1-tx if attr&16 else tx;ey=h-1-ty if attr&32 else ty;tile=n+[0,1,4,5][ex]+[0,2,8,10][ey]
     for y in range(8):
      for x in range(8):
       px=7-x if attr&16 else x;py=7-y if attr&32 else y;by=gfx[tile*32+py*4+px//2];pen=by>>4 if px%2==0 else by&15
       lookup=prom[((bank>>4)*16)+pen]&15
       if not lookup:continue
       i=circ*64+lookup;c=pal[2*i]|pal[2*i+1]<<8;rgb=tuple((((c>>s)&31)<<3)|(((c>>s)&31)>>2) for s in (0,5,10));xx=sx-minx+tx*8+x;yy=sy-miny+ty*8+y
       if 0<=xx<64 and 0<=yy<64:img.putpixel((xx,yy),(*rgb,255))
  img.save(out/f'{frame}-{circ}.png');print(frame,circ,entries)
