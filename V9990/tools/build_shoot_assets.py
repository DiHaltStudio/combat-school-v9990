#!/usr/bin/env python3
"""Build a B1 shooting-range background and small transparent atlas."""
from pathlib import Path
from PIL import Image, ImageDraw
from arcade_font import draw_text, shadow_pen

p=Path('build/demo')
field=Image.open('assets/shoot/field.png').convert('RGB')
draw=ImageDraw.Draw(field)
# The reference's player/CPU scores are replaced by live counters.
background=field.getpixel((5,185))
draw.rectangle((9,179,48,190),fill=background)
draw.rectangle((204,179,241,190),fill=background)
# Only the first two rows have empty slots; extra rows are added as hits land.
# The source recording contains remnants below the original grid. Clear the
# entire area reserved for extra rows before recreating the two empty rows.
draw.rectangle((8,196,95,211),fill=background)
for y in (196,199):
 for n in range(22):
  for left in (8,160):          # player 1 and, idle, player 2 (as the arcade)
   draw.rectangle((left+n*4,y,left+2+n*4,y+1),fill=(20,20,16))
# The red QUALIFY labels of the arcade (assets/shoot/qualify.png: its HUD
# plane, rows 200..207, labels at x 9..38 and 217..246), where the score
# digits were.
# Player 2's counter, idle at 0000 as in the arcade (x 208), in the field.
draw_text(draw,208,180,'0000',(239,239,239),scale=2,shadow=(33,33,33))
qualify=Image.open('assets/shoot/qualify.png')
for start,source in ((8,9),(218,217)):
 draw.rectangle((start,189,min(start+40,255),196),fill=background)
 label=qualify.crop((source,0,source+30,8))
 field.paste(label,(start,189),label)   # glyph rows 190..195, below the counters
# assets/shoot/field.png is the arcade's playfield (MAME: plane 1 rebuilt by
# tools/render_background.py from build/mame-shoot/frame-4400, rows 12..223,
# the 4 black rows on top filled with the sky; plus the green player-2
# soldier of snapshot 0100): 21 colours. Pens 1-9
# and 11 take them, reduced as tools/build_progress_assets.py arcade_palette;
# pen 10 is the shooter's orange shirt, 12 the red of QUALIFY.
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from arcade_palette import arcade_palette
field_colours=arcade_palette(field.crop((0,0,256,188)),10)
colours=field_colours[:9]+[(232,130,0)]+field_colours[9:10]
palette=[v for rgb in colours for v in rgb]
pixels=[]
for position,(r,g,b) in enumerate(field.getdata()):
 if r>200 and g<40 and b<40: pixels.append(12)
 elif (r,g,b)==(239,239,239): pixels.append(14)
 else: pixels.append(1+min((i for i in range(11) if i!=9),key=lambda i:sum((v-c)**2 for v,c in zip((r,g,b),colours[i]))))
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
import arcade_sprites
from extract_shoot_goal import celebration_patches, target_images
cleaned=field.copy()
poses=[]
for name in ('left','center','right'):
 image=Image.open(f'assets/shoot/pose-{name}.png').convert('RGB')
 # Remove the recorded score fragment at the left edge of the patch.
 ImageDraw.Draw(image).rectangle((0,48,9,63),fill=background)
 encoded=[]
 for position,(r,g,b) in enumerate(image.getdata()):
  y=130+position//48
  if 153<=y<=169 and r>135 and 55<g<180 and r>g*1.15 and g>b*1.3: encoded.append(10)
  else: encoded.append(1+min(range(11),key=lambda i:sum((v-c)**2 for v,c in zip((r,g,b),colours[i]))))
 poses.append(encoded)
# Qualified celebration from the arcade (tools/extract_shoot_goal.py): the
# shooter stands up, then raises his arm. Same 48x64 patch at x=40, y=130.
for image,shirt in celebration_patches(cleaned):
 encoded=[]
 for position,(r,g,b) in enumerate(image.getdata()):
  if (position%48,position//48) in shirt: encoded.append(10)
  else: encoded.append(1+min(range(11),key=lambda i:sum((v-c)**2 for v,c in zip((r,g,b),colours[i]))))
 poses.append(encoded)
pose_bytes=bytearray()
for pixels_pose in poses:
 pose_bytes.extend(bytes(pixels_pose[i]*16+pixels_pose[i+1] for i in range(0,len(pixels_pose),2)))
(p/'shoot-poses.bin').write_bytes(pose_bytes+bytes([255])*(16384-len(pose_bytes)))
raw=bytes(pixels[i]*16+pixels[i+1] for i in range(0,len(pixels),2))
(p/'shoot-field.bin').write_bytes(raw+bytes([255])*(32768-len(raw)))
# The ground's pen under the Step 6 grid (src/shoot_b1.asm shoot_grid_clear).
ground=pixels[198*256+80]
(p/'shoot.inc').write_text(f'SHOOT_GROUND equ 0x{ground*17:02x}   ; pen {ground} in both nibbles\n')
pal=[0,0,0]+palette+[240,16,16, 216,24,192, 248,248,248, 248,184,16]
(p/'shoot-palette.bin').write_bytes(bytes(c>>3 for c in pal))
# Rows 0-31 as before; rows 32-63 hold the near target and the final labels.
atlas=Image.new('P',(256,64),0); d=ImageDraw.Draw(atlas)
def paste_indexed(image,x,y):
 for (px,py) in ((i%image.width,i//image.width) for i in range(image.width*image.height)):
  r,g,b,a=image.getpixel((px,py))
  if a: atlas.putpixel((x+px,y+py),1+min(range(15),key=lambda i:sum((v-c)**2 for v,c in zip((r,g,b),pal[3+3*i:6+3*i]))))
# Arcade targets: the middle-distance one (16x24) for the far rows and the
# near one (16x32) for the two lower rows.
middle,near=target_images()
paste_indexed(middle,0,0)
paste_indexed(near,0,32)
for a in ((17,1,21,1),(17,1,17,5),(26,1,30,1),(30,1,30,5),
          (17,10,17,14),(17,14,21,14),(26,14,30,14),(30,10,30,14),
          (21,8,26,8),(24,5,24,11)):
 d.line(a,fill=12,width=1)
# Digits 0-9 of the counters, clock and score: the arcade's 8x8 font
# (its counters 0001/0000), 8 rows of the 10 the copies take.
draw_text(d,32,0,'0123456789',14,scale=2,shadow=shadow_pen(pal))
for n in range(22): d.rectangle((112+n*4,0,114+n*4,2),fill=15)
# Projectile in x=202..206, rows 0..4. Amber outline, near-white center.
d.polygon(((204,0),(206,2),(204,4),(202,2)),fill=15)
d.line((204,1,204,3),fill=14)
# The target occupies x=0..15 and extends through row 23. Keep the
# success label outside its complete 16x24 source rectangle.
draw_text(d,32,16,'YOU MADE IT',14,scale=2,shadow=shadow_pen(pal))
draw_text(d,224,16,'FAIL',14,scale=2,shadow=shadow_pen(pal))
# Final qualified screen, as in the arcade: PLAYER 1 / (NICK) above YOU MADE IT.
draw_text(d,16,32,'PLAYER 1',14,scale=2,shadow=shadow_pen(pal))
draw_text(d,80,32,'(NICK)',14,scale=2,shadow=shadow_pen(pal))
# Lost (arcade): PLAYER 1 / (NICK) above YOU BLEW IT in red, at x=32, y=48.
draw_text(d,32,48,'YOU BLEW IT',12,scale=2,shadow=shadow_pen(pal))
# Red 1P of the single game score (src/shoot_b1.asm shoot_score), x 16-31.
draw_text(d,16,48,'1P',12,scale=2,shadow=shadow_pen(pal))
# Step 6 arcade boards (tools/extract_step6_targets.py), six 16x32 frames at
# x=128..223, y=32: ring and red standing, half-raised and lying.
paste_indexed(Image.open('assets/step6/arcade-targets.png').convert('RGBA'),128,32)
px=list(atlas.getdata()); raw=bytes(px[i]*16+px[i+1] for i in range(0,len(px),2))
assert len(raw)==8192
# The arcade's explosion on a hit target (tools/extract_target_explosion.py):
# 32 more rows in the bank's padding, uploaded to y=640 (src/shoot_b1.asm):
# fire at x 0, smoke at x 32 (32x32 each), the last puffs at x 64 (16x32).
atlas=Image.new('P',(256,32),0)
paste_indexed(Image.open('assets/shoot/explosion.png').convert('RGBA'),0,0)
px=list(atlas.getdata()); raw+=bytes(px[i]*16+px[i+1] for i in range(0,len(px),2))
(p/'shoot-atlas.bin').write_bytes(raw+bytes([255])*(16384-len(raw)))
preview=Image.new('P',field.size);preview.putpalette(pal+[0]*(768-len(pal)));preview.putdata(pixels);preview.save(p/'shoot-field-preview.png')
