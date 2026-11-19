#!/usr/bin/env python3
"""Experimental arcade background reconstruction; no sprite or priority mixing."""
import argparse
from pathlib import Path
from zipfile import ZipFile
from PIL import Image
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('capture',type=Path)
p.add_argument('--rom',default=str(Path(__file__).resolve().parents[2] / 'ARCADE' / 'original' / 'combatsc.zip'))
p.add_argument('--vreg', type=lambda x:int(x,0), help='override suspected incomplete trace')
p.add_argument('--out',type=Path,default=Path('build/background'))
a=p.parse_args()
regs={}
for line in (a.capture/'registers.txt').read_text().splitlines():
 k,v=line.split('='); regs[k]=v
if '??' in regs['ctrl0']+regs['ctrl1'] or regs['vreg']=='unknown': raise ValueError('Incomplete register capture')
controls=[[int(x,16) for x in regs[f'ctrl{i}'].split()] for i in range(2)]
vreg=a.vreg if a.vreg is not None else int(regs['vreg'],16)
pal=(a.capture/'palette.bin').read_bytes()
with ZipFile(a.rom) as z:
 for circuit,names in enumerate((('611g07.rom','611g08.rom','611g05.h15'),('611g11.rom','611g12.rom','611g09.h7'))):
  even,odd,prom=[z.read(n) for n in names]; gfx=bytearray(len(even)*2);gfx[::2],gfx[1::2]=even,odd
  ram=(a.capture/f'videoram{circuit}.bin').read_bytes(); scroll=(a.capture/f'scrollram{circuit}.bin').read_bytes(); ctrl=controls[circuit]
  img=Image.new('RGBA',(256,224)); pixels=img.load()
  for y in range(224):
   sy=(y+16+ctrl[2])&255
   sxoff=scroll[sy//8] if ctrl[1]&2 else ctrl[0]+((ctrl[1]&1)<<8)
   for x in range(256):
    sx=(x+sxoff)&255; t=sy//8*32+sx//8; attr=ram[t]
    bank=max(0,4*((vreg>>(4*circuit)&15)-1)) if attr&0xb0 else 0
    bank+=bool(attr&0x80)+2*bool(attr&0x10)+4*bool(attr&0x20)
    number=ram[t+0x400]+256*bank
    b=gfx[number*32+(sy%8)*4+(sx%8)//2]; pen=(b>>4) if sx%2==0 else b&15
    group=1+4*circuit+(2 if ctrl[6]&0x10 else 0)
    idx=(group<<4)|(prom[(attr&15)*16+pen]&15)
    c=pal[idx*2]|pal[idx*2+1]<<8
    rgb=tuple((((c>>s)&31)<<3)|(((c>>s)&31)>>2) for s in (0,5,10))
    pixels[x,y]=(*rgb,255 if pen else 0)
  a.out.mkdir(parents=True,exist_ok=True);img.save(a.out/f'plane{circuit}.png')
