#!/usr/bin/env python3
"""Extract the first rescue room and the player from captured MAME video RAM."""
from pathlib import Path
from zipfile import ZipFile
from PIL import Image
import subprocess

root=Path('build/mission/mame')
out=Path('assets/mission');out.mkdir(parents=True,exist_ok=True)
subprocess.run(['python3','tools/render_background.py',str(root/'frame-4760'),
                '--out','build/mission/background'],check=True)
Image.open('build/mission/background/plane1.png').crop((0,0,256,212)).save(out/'field.png')
screen=root/'combatsc/0000.png'
if screen.exists():
    Image.open(screen).convert('RGB').crop((0,16,256,32)).save(out/'damage-hud.png')
with ZipFile('../ARCADE/original/combatsc.zip') as z:
    groups=[tuple(z.read(n) for n in names) for names in
            (('611g07.rom','611g08.rom','611g06.h14'),('611g11.rom','611g12.rom','611g10.h6'))]
graphics=[]
for even,odd,prom in groups:
    gfx=bytearray(len(even)*2);gfx[::2]=even;gfx[1::2]=odd
    graphics.append((gfx,prom))
frames={'idle':(root,4760,1),'walk1':(root,4772,1),'walk2':(root,4780,1),'walk3':(root,4788,1),'walk4':(root,4796,1),
        'jump1':(root,4828,1),'jump2':(root,4836,1),'jump3':(root,4844,1)}
attack=Path('build/mission/attack-mame')
if (attack/'frame-4776').exists():
    frames.update({'attack1':(attack,4772,1),'attack2':(attack,4776,1),'attack3':(attack,4784,1)})
airkick=Path('build/mission/airkick-mame')
if (airkick/'frame-4800').exists():
    frames.update({'airkick':(airkick,4800,1),'enemy-walk1':(airkick,4796,0),
                   'enemy-walk2':(airkick,4804,0),'enemy-walk3':(airkick,4812,0)})
enemy=Path('build/mission/enemy-mame')
if (enemy/'frame-5172').exists():
    frames.update({'enemy-hit':(enemy,5116,0),'enemy-fall':(enemy,5140,0),'enemy-down':(enemy,5172,0)})
grab=Path('build/mission/enemyattack-mame')
if (grab/'frame-5236').exists():
    frames.update({'player-grab1':(grab,5156,1),'player-grab2':(grab,5176,1),
                   'player-grab3':(grab,5204,1),'player-drop':(grab,5236,1),
                   'enemy-stab':(grab,5164,0)})
course=Path('build/mission/course-mame')
if (course/'frame-4827').exists():
    frames.update({'orange-walk1':(course,4803,0),'orange-walk2':(course,4827,0)})
orangehit=Path('build/mission/orangehit-mame')
if (orangehit/'frame-4874').exists():
    frames.update({'orange-hit':(orangehit,4824,0),'orange-knee':(orangehit,4842,0),
                   'orange-fall':(orangehit,4858,0),'orange-down':(orangehit,4874,0)})
for name,(base,frame,circuit) in frames.items():
    p=base/f'frame-{frame:04d}';pal=(p/'palette.bin').read_bytes()
    gfx,prom=graphics[circuit]
    data=(p/f'videoram{circuit}.bin').read_bytes()[0x1800:0x1d00];entries=[]
    for i in range(64):
        n,bank,sy,sx,attr=data[i*5:i*5+5]
        sx-=256 if attr&1 else 0;sy-=256 if sy>=240 else 0
        lo,hi=(200,255) if name.startswith('orange-walk') else ((-8 if circuit==0 else 30),170)
        if name=='enemy-stab': lo,hi=140,200  # right-hand attacker, facing left
        if not (lo<=sx<=hi and 50<=sy<=200 and bank>>4==0):continue
        tile=((n+((bank&3)<<8)+((attr&0xc0)<<4))<<2)+((bank>>2)&3)
        typ=attr&14;w,h={6:(1,1),4:(1,2),2:(2,1),0:(2,2),8:(4,4)}.get(typ,(1,1))
        tile &= ~(2 if typ==4 else 1 if typ==2 else 3 if typ in (0,8) else 0)
        entries.append((sx,sy,tile,w,h,attr,bank))
    assert entries,(name,frame)
    minx=min(e[0] for e in entries);miny=min(e[1] for e in entries)
    image=Image.new('RGBA',(64,64))
    for sx,sy,n,w,h,attr,bank in entries:
        for ty in range(h):
            for tx in range(w):
                ex=w-1-tx if attr&16 else tx;ey=h-1-ty if attr&32 else ty
                tile=n+[0,1,4,5][ex]+[0,2,8,10][ey]
                for y in range(8):
                    for x in range(8):
                        px=7-x if attr&16 else x;py=7-y if attr&32 else y
                        byte=gfx[tile*32+py*4+px//2];pen=byte>>4 if px%2==0 else byte&15
                        lookup=prom[((bank>>4)*16)+pen]&15
                        if not lookup:continue
                        index=circuit*64+lookup;c=pal[index*2]|pal[index*2+1]<<8
                        rgb=tuple((((c>>shift)&31)<<3)|(((c>>shift)&31)>>2) for shift in (0,5,10))
                        xx=sx-minx+tx*8+x;yy=sy-miny+ty*8+y
                        if 0<=xx<64 and 0<=yy<64:image.putpixel((xx,yy),(*rgb,255))
    image.save(out/(name+'.png'))
    print(name,frame,len(entries),image.getbbox())
