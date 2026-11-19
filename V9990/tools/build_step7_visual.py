#!/usr/bin/env python3
"""Build a standalone fight prototype from locally captured arcade assets."""
from pathlib import Path
from PIL import Image,ImageDraw
from impact_flash import draw_impact_flash
p=Path('build/step7');p.mkdir(parents=True,exist_ok=True)
a=Path('assets/step7')
colours=[(0,0,0),(48,64,80),(96,112,128),(144,160,176),
 (64,64,64),(104,104,104),(152,152,152),(224,224,208),
 (216,16,8),(240,152,24),(248,192,96),(184,136,104),
 (104,72,56),(24,72,40),(64,112,64),(136,160,120)]
pal=[v for colour in colours for v in colour]
ref=Image.new('P',(1,1));ref.putpalette(pal+[0]*(768-len(pal)))
# Index 3 is unused by the indexed arcade captures. Keep the existing
# quantisation palette and assign this free hardware entry to violet.
runtime_pal=pal.copy();runtime_pal[9:12]=[200,48,208]
(p/'palette.bin').write_bytes(bytes(v>>3 for v in runtime_pal))
def indexed(image):
 return image.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE)
def pack(image):
 v=list(image.getdata());return bytes(v[i]*16+v[i+1] for i in range(0,len(v),2))
field=indexed(Image.open(a/'field.png'))
# The capture was made after the player had already received one hit.
# Restore the eighth cell to empty so damage starts at zero.
ImageDraw.Draw(field).rectangle((97,45,103,52),fill=field.getpixel((94,48)))
# The ROM draws the arcade clock (x 104..151, y 26..38) into this area.
ImageDraw.Draw(field).rectangle((104,26,151,38),fill=0)
raw=pack(field);assert len(raw)==27136
(p/'field.bin').write_bytes(raw+bytes(32768-len(raw)))
atlas=Image.new('P',(256,512),0)
for i,name in enumerate(('player-idle','player-kick','player-jump','instructor-idle')):
 im=Image.open(a/(name+'.png')).convert('RGBA')
 # Captured poses have different origins. Keep the support foot at the same
 # height as the standing pose; the jump height is applied by game logic.
 if name in ('player-kick','player-jump'):
  aligned=Image.new('RGBA',im.size)
  aligned.alpha_composite(im,(0,15))
  im=aligned
 if name.startswith('player-'):
  bbox=im.getbbox()
  part=im.crop(bbox)
  part=part.resize((round(part.width*1.03),round(part.height*1.05)),Image.Resampling.NEAREST)
  enlarged=Image.new('RGBA',im.size)
  enlarged.alpha_composite(part,(bbox[0],bbox[3]-part.height))
  im=enlarged
 atlas.paste(indexed(im),(64*i,0),im.getchannel('A'))
 if name.startswith('player-'):
  bbox=im.getbbox()
  reflected=Image.new('RGBA',im.size)
  reflected.alpha_composite(im.crop(bbox).transpose(Image.Transpose.FLIP_LEFT_RIGHT),bbox[:2])
  atlas.paste(indexed(reflected),(64*i,64),reflected.getchannel('A'))
cpu=Image.open(a/'instructor-idle.png').convert('RGBA')
kick=Image.open(a/'instructor-kick.png').convert('RGBA')
atlas.paste(indexed(kick),(192,64),kick.getchannel('A'))
for x,im in ((192,cpu),(128,kick)):
 bbox=im.getbbox()
 reflected=Image.new('RGBA',im.size)
 reflected.alpha_composite(im.crop(bbox).transpose(Image.Transpose.FLIP_LEFT_RIGHT),bbox[:2])
 atlas.paste(indexed(reflected),(x,128),reflected.getchannel('A'))
pen=ImageDraw.Draw(atlas)
def enlarged_player(im):
 bbox=im.getbbox();part=im.crop(bbox)
 part=part.resize((round(part.width*1.03),round(part.height*1.05)),Image.Resampling.NEAREST)
 out=Image.new('RGBA',im.size);out.alpha_composite(part,(bbox[0],bbox[3]-part.height));return out
# Arcade moves added from MAME (tools/extract_step7_moves.py): crouch and
# sweeping kick at row 448 (mirrored at x+128) and both arms raised after
# winning at (0,128), VRAM y 896.
for i,name in enumerate(('player-crouch','player-lowkick')):
 im=enlarged_player(Image.open(a/(name+'.png')).convert('RGBA'))
 atlas.paste(indexed(im),(64*i,448),im.getchannel('A'))
 bbox=im.getbbox();reflected=Image.new('RGBA',im.size)
 reflected.alpha_composite(im.crop(bbox).transpose(Image.Transpose.FLIP_LEFT_RIGHT),bbox[:2])
 atlas.paste(indexed(reflected),(128+64*i,448),reflected.getchannel('A'))
victory=enlarged_player(Image.open(a/'player-victory.png').convert('RGBA'))
atlas.paste(indexed(victory),(0,128),victory.getchannel('A'))
# Small transparent impact flashes. Orange is the player's hit and violet
# is the instructor's hit; white adds the bright core seen in the arcade.
for ox,colour in ((96,9),(112,3)):
 draw_impact_flash(pen,ox,128,colour,7)
for i,name in enumerate(('player-walk1','player-walk2','instructor-walk1','instructor-walk2')):
 im=Image.open(a/(name+'.png')).convert('RGBA')
 if name.startswith('player-'):
  bbox=im.getbbox();part=im.crop(bbox)
  part=part.resize((round(part.width*1.03),round(part.height*1.05)),Image.Resampling.NEAREST)
  enlarged=Image.new('RGBA',im.size)
  enlarged.alpha_composite(part,(bbox[0],bbox[3]-part.height));im=enlarged
 atlas.paste(indexed(im),(64*i,192),im.getchannel('A'))
 bbox=im.getbbox();reflected=Image.new('RGBA',im.size)
 reflected.alpha_composite(im.crop(bbox).transpose(Image.Transpose.FLIP_LEFT_RIGHT),bbox[:2])
 atlas.paste(indexed(reflected),(64*i,256),reflected.getchannel('A'))
for i,name in enumerate(('instructor-hit','instructor-down','player-hit','player-down')):
 im=Image.open(a/(name+'.png')).convert('RGBA')
 atlas.paste(indexed(im),(64*i,320),im.getchannel('A'))
 bbox=im.getbbox();reflected=Image.new('RGBA',im.size)
 reflected.alpha_composite(im.crop(bbox).transpose(Image.Transpose.FLIP_LEFT_RIGHT),bbox[:2])
 atlas.paste(indexed(reflected),(64*i,384),reflected.getchannel('A'))
raw=pack(atlas)
(p/'atlas.bin').write_bytes(raw+bytes(65536-len(raw)))

# Three mapper banks instead of the six uncompressed battle-graphics banks.
# Each stream remains within a bank and decodes directly into V9990 VRAM.
def rle_bank(data):
 encoded=bytearray();i=0
 while i<len(data):
  j=i+1
  while j<len(data) and data[j]==data[i] and j-i<255:j+=1
  encoded.extend((j-i,data[i]));i=j
 encoded.append(0)
 assert len(encoded)<=16384,len(encoded)
 return bytes(encoded+bytes([255])*(16384-len(encoded)))
(p/'field-rle-bank.bin').write_bytes(rle_bank((p/'field.bin').read_bytes()[:27136]))
(p/'atlas0-rle-bank.bin').write_bytes(rle_bank(raw[:32768]))
(p/'atlas1-rle-bank.bin').write_bytes(rle_bank(raw[32768:]))
# Second atlas from MAME (tools/extract_step7_extra.py): instructor punch and
# sweep, more player poses, clock digits and the arcade texts; VRAM y 1280.
extra=Image.open(a/'arcade-extra.png').convert('RGBA')
extra_pens=Image.new('P',extra.size,0)
extra_pens.paste(indexed(extra),(0,0),extra.getchannel('A').point(lambda v:255 if v else 0))
(p/'atlas2.bin').write_bytes(pack(extra_pens))
(p/'atlas2-rle-bank.bin').write_bytes(rle_bank(pack(extra_pens)))

# Third atlas (tools/extract_step7_moves2.py, 16-nov): the player's moves the
# port lacked, at VRAM y 1600 (src/step7_visual.asm atlas3_source). Pose i at
# x (i%4)*64, y 1600+(i//4)*64; facing left, 192 lines lower.
#   0-1 stepping back, 2 kick in the air, 3-8 the high kick
ATLAS3 = ['player-backwalk1', 'player-backwalk2', 'player-airkick'] + \
         [f'player-highkick{i}' for i in range(1, 7)]
atlas3 = Image.new('P', (256, 384), 0)
for i, name in enumerate(ATLAS3):
 im = enlarged_player(Image.open(a/(name+'.png')).convert('RGBA'))
 x, y = (i % 4)*64, (i // 4)*64
 atlas3.paste(indexed(im), (x, y), im.getchannel('A'))
 bbox = im.getbbox(); reflected = Image.new('RGBA', im.size)
 reflected.alpha_composite(im.crop(bbox).transpose(Image.Transpose.FLIP_LEFT_RIGHT), bbox[:2])
 atlas3.paste(indexed(reflected), (x, y+192), reflected.getchannel('A'))
(p/'atlas3-rle-bank.bin').write_bytes(rle_bank(pack(atlas3)))
atlas3.putpalette(runtime_pal+[0]*(768-len(runtime_pal)))
atlas3.save(p/'atlas3-preview.png')
