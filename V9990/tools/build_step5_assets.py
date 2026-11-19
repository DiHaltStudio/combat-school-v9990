#!/usr/bin/env python3
"""Build compact Step 5 screens and animation patches from checked-in art."""
from pathlib import Path
from PIL import Image, ImageDraw
from arcade_font import draw_text, shadow_pen
p=Path('build/step5');p.mkdir(parents=True,exist_ok=True)
art=Path('assets/step5')
# Shared V9990 palette; reserve pen 0 for black, 14 for red and 15 for white.
colours=[(0,0,0),(32,40,32),(54,73,54),(79,99,76),(109,123,101),
         (70,50,40),(101,72,57),(140,96,72),(177,119,91),(211,150,116),
         (241,183,148),(154,101,28),(211,147,38),(241,193,69),(240,8,8),(248,248,240)]
pal=[c for rgb in colours for c in rgb]
ref=Image.new('P',(1,1));ref.putpalette(pal+[0]*(768-len(pal)))
def idx(im):return im.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE)
def pack(im):
 data=list(im.getdata());return bytes(data[i]*16+data[i+1] for i in range(0,len(data),2))
def imagefile(name):return Image.open(art/('arcade-'+name+'.png')).convert('RGB')
# Arcade screens (tools/extract_step5_arcade.py) in arcade coordinates. The
# extra strip (patches, digits and labels) is stored at VRAM y 980..1151:
# its first 44 rows after the overhead picture, the rest in the atlas bank.
extra=Image.open(art/'arcade-extra.png').convert('RGBA')
extra_pens=idx(extra)
mask=extra.getchannel('A').point(lambda a:255 if a else 0)
strip=Image.new('P',extra.size,0);strip.paste(extra_pens,(0,0),mask)
# Red 1P of the single game score (src/step5_visual.asm draw_score) in the
# free strip area at x 128-143, rows 140-149 (VRAM y 1120).
draw_text(ImageDraw.Draw(strip),128,140,'1P',14,scale=2,shadow=shadow_pen(pal))
for name in ('front','struggle'):
 im=idx(imagefile(name));page=Image.new('P',(256,256),0);page.paste(im,(0,0))
 if name=='struggle':page.paste(strip.crop((0,0,256,44)),(0,212))
 (p/(name+'.bin')).write_bytes(pack(page))
 im.putpalette(pal+[0]*(768-len(pal)));im.save(p/(name+'-preview.png'))
# The victory pose changes both bodies. Store the complete image as RLE and
# replace the no-longer-needed intro page when the contest ends; this avoids
# seams without reserving another 32 KiB pair of ROM banks.
victory=pack(idx(imagefile('finish')))
encoded=bytearray()
i=0
while i<len(victory):
 j=i+1
 while j<len(victory) and victory[j]==victory[i] and j-i<255:
  j+=1
 encoded.extend((j-i,victory[i]));i=j
encoded.append(0)
(p/'victory-rle.bin').write_bytes(encoded)
(p/'victory-reference.bin').write_bytes(victory)
# The CPU win is the overhead picture with the CPU-win patch at (54,70).
cpuwin=idx(imagefile('struggle'));cpuwin.paste(strip.crop((0,86,128,172)),(54,70))
(p/'cpuwin-reference.bin').write_bytes(pack(cpuwin))
(p/'atlas.bin').write_bytes(pack(strip.crop((0,44,256,172))))
(p/'palette.bin').write_bytes(bytes(v>>3 for v in pal))
