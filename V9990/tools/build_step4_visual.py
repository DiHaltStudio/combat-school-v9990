#!/usr/bin/env python3
"""Build the standalone Firing Range II prototype from checked-in assets."""
from pathlib import Path
import json
from PIL import Image,ImageDraw
from arcade_font import draw_text, shadow_pen
out=Path('build/step4');out.mkdir(parents=True,exist_ok=True)
art=Path('assets/step4')
colours=[(0,0,0),(0,192,184),(176,152,112),(144,128,96),(112,104,72),
         (8,88,48),(24,128,64),(216,136,24),(200,160,120),(248,248,232),
         (248,24,16),(208,24,160),(48,48,40),(112,88,64),(40,128,128),(224,200,152)]
palette=[v for rgb in colours for v in rgb]
(out/'palette.bin').write_bytes(bytes(v>>3 for v in palette))
def indexed(im):
 im=im.convert('RGB');cache={};data=[]
 for rgb in im.getdata():
  if rgb not in cache:cache[rgb]=min(range(1,16),key=lambda i:sum((a-b)**2 for a,b in zip(rgb,colours[i])))
  data.append(cache[rgb])
 result=Image.new('P',im.size);result.putdata(data);return result
def packed(im):
 p=list(im.getdata());return bytes(p[i]*16+p[i+1] for i in range(0,len(p),2))
field_source=Image.open(art/'field.png').convert('RGB')
field=indexed(field_source)
# The turquoise mountain is close to the sky in the restricted palette.
# Assign its pixels a dedicated shade so its silhouette remains legible.
for y in range(4,38):
 for x in range(256):
  r,g,b=field_source.getpixel((x,y))
  if r<90 and 90<g<180 and 90<b<180 and abs(g-b)<30:
   field.putpixel((x,y),14)
d=ImageDraw.Draw(field)
# The default Pillow font is taller than the space above the two grids.
# A compact, explicit pixel font keeps the label clear of the first row.
glyphs = {
 'Q':('111','101','101','111','001'), 'U':('101','101','101','101','111'),
 'A':('010','101','111','101','101'), 'L':('100','100','100','100','111'),
 'I':('111','010','010','010','111'), 'F':('111','100','110','100','100'),
 'Y':('101','101','010','010','010')}
for n, letter in enumerate('QUALIFY'):
 for y, row in enumerate(glyphs[letter]):
  for x, pixel in enumerate(row):
   if pixel == '1': d.point((8+n*4+x,191+y),fill=10)
for y in (197,201):
 for x in range(26):d.rectangle((8+x*4,y,10+x*4,y+2),fill=12)
patterns=('111101101101111','010110010010111','111001111100111','111001111001111','101101111001001','111100110001111','111100111101111','111001001001001','111101111101111','111101111001111')
def digit(draw,x,y,n):
 for row in range(5):
  for col in range(3):
   if patterns[n][row*3+col]=='1':draw.rectangle((x+col*2,y+row*2,x+col*2+1,y+row*2+1),fill=9)
# Arcade clock 0:SS.t at arcade (56,30), ROM y = arcade y - 14. The fixed
# "0:" and "." are part of the field; the ROM draws SS at x 72 and t at 96.
digit(d,56,16,0)
d.rectangle((67,18,68,19),fill=9);d.rectangle((67,22,68,23),fill=9)
d.rectangle((91,24,92,25),fill=9)
def masked(im):
 pixels=indexed(im);alpha=im.getchannel('A').point(lambda a:255 if a>=128 else 0)
 result=Image.new('P',im.size,0);result.paste(pixels,(0,0),alpha);return result
# Arcade shooter poses (tools/extract_range2_sprites.py), 32x60 each: idle,
# right stride/close, left stride/close, standing up, arm raised. They form
# a strip at VRAM y 724..783: its first 44 rows use the free lines after the
# 212-line field, the other 16 the first atlas rows.
strip=masked(Image.open(art/'arcade-shooter.png').convert('RGBA'))
page=Image.new('P',(256,256),0);page.paste(field,(0,0));page.paste(strip.crop((0,0,224,44)),(0,212))
(out/'field.bin').write_bytes(packed(page))
atlas=Image.new('P',(256,128),0)
atlas.paste(strip.crop((0,44,224,60)),(0,0))
# Arcade targets in five depth sizes: front, side facing right, side facing
# left, packed in rows 64 and 96. The table (row, then width, x, height per
# size) is read by target_size.
targets=Image.open(art/'arcade-targets.png').convert('RGBA')
# Fixed roles keep the olive vehicles apart from the sand (nearest colour
# would turn them into sand browns): body and light dark/light green.
TARGET_PEN={(90,107,66):5,(140,156,107):6,(33,49,33):12,(82,66,74):13,(99,66,41):13,
            (181,198,123):15,(255,255,0):7,(214,0,132):11}
def target_pens(im):
 result=Image.new('P',im.size,0)
 result.putdata([TARGET_PEN[p[:3]] if p[3] else 0 for p in im.getdata()]);return result
sets=bytearray();x=0;row=64
for kind in ('front','right','left'):
 if x>160:x=0;row=96
 sets.append(row)
 for band in range(5):
  im=targets.crop((band*32,0 if kind=='front' else 32,band*32+32,64 if kind!='front' else 32))
  im=im.crop(im.getbbox())
  if kind=='left':im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
  pens=target_pens(im);atlas.paste(pens,(x,row),pens.point(lambda v:255 if v else 0,'L'));sets+=bytes((im.width,x,im.height));x+=im.width+1
(out/'target-sets.bin').write_bytes(bytes(sets))
d=ImageDraw.Draw(atlas)
for n in range(10):digit(d,64+n*8,16,n)
draw_text(d,0,28,'PLAYER 1',9,scale=2,shadow=shadow_pen(palette))
draw_text(d,64,28,'(NICK)',9,scale=2,shadow=shadow_pen(palette))
draw_text(d,112,28,'YOU MADE IT',9,scale=2,shadow=shadow_pen(palette))
draw_text(d,120,100,'YOU BLEW IT',10,scale=2,shadow=shadow_pen(palette))   # lost (arcade), red
draw_text(d,208,28,'1P',10,scale=2,shadow=shadow_pen(palette))   # single game score (draw_score), red
d.text((216,48),'FAIL',fill=10)
for x in range(26):d.rectangle((x*4,48,x*4+2,50),fill=10)
# Red/orange projectile with a bright centre, observed in the arcade capture.
d.polygon([(113,48),(114,48),(115,49),(115,51),(114,53),(113,52),(112,50)],fill=10)
d.point((113,49),fill=9);d.point((114,50),fill=9);d.point((114,52),fill=7)
# Captured arcade flash, burning burst and dispersing fragments. Preserve alpha
# when quantizing to the existing 16-colour palette and fixed 16x16 atlas slots.
for x,name in zip((128,144,160),('flash','fire','embers')):
    sprite=masked(Image.open(art/'effects'/f'{name}.png').convert('RGBA'))
    atlas.paste(sprite,(x,48))
(out/'atlas.bin').write_bytes(packed(atlas))

# 30 Hz no-fire reference frames; data are read sequentially from banks 4–5.
import json
sequence=json.loads((art/'recorded-sequence.json').read_text())
rows=json.loads((art/'robot-paths.json').read_text())
if len(rows)!=sequence['frames'] or any(len(row)>16 or any(len(robot)!=4 for robot in row) for row in rows):
 raise ValueError('invalid robot path records')
data=bytes(v for row in rows for v in (len(row), *(v for robot in row for v in robot)))
if sequence['fps']!=30 or sequence['frames']!=1380 or len(data)!=sequence['bytes'] or len(data)>32768:
 raise ValueError('invalid recorded robot sequence')
(out/'recorded-sequence.bin').write_bytes(data+bytes([0xff])*(32768-len(data)))
