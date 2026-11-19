#!/usr/bin/env python3
"""Build provisional graphics for the standalone vertical-camera test."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
from arcade_font import draw_text, shadow_pen

out = Path('build/step3')
out.mkdir(parents=True, exist_ok=True)
art = Path('assets/step3')
# Palette roles are fixed by the code and hand-drawn graphics (1-2 sand,
# 3 dark green, 4 player shirt, 5 CPU shirt/light green, 6 skin, 7 trousers,
# 8 white, 9-10 water, 11 brown, 12 dark, 13 red, 14 grey, 15 water). The
# colours are the arcade's (tools/build_ironman_course.py); pen 15 is the
# arcade's animated water entry, rotated by the race loop.
colours = [(0,0,0),(214,173,123),(189,156,123),(49,90,57),
           (232,128,0),(115,148,115),(189,140,115),(90,115,99),
           (239,239,239),(0,148,156),(0,165,173),(148,115,90),
           (49,49,49),(240,16,0),(115,107,99),(0,140,181)]
pal = [v for rgb in colours for v in rgb]
(out/'visual-palette.bin').write_bytes(bytes(v >> 3 for v in pal))
def indexed(image):
    """Map real RGB pixels to the fixed V9990 palette, reserving pen zero."""
    result = Image.new('P', image.size)
    cache = {}
    values = []
    for rgb in image.convert('RGB').getdata():
        if rgb not in cache:
            cache[rgb] = min(range(1,16),key=lambda i:sum((a-b)**2 for a,b in zip(rgb,colours[i])))
        values.append(cache[rgb])
    result.putdata(values)
    return result

world = Image.new('P', (256,256), 1)
sand = indexed(Image.open(art/'sand.png'))
bush = indexed(Image.open(art/'bush.png'))
puddle = indexed(Image.open(art/'puddle.png').resize((24,12),Image.Resampling.LANCZOS))
for y in range(0,256,24):
    for x in range(0,256,24):
        world.paste(sand,(x,y))
for lane in (0,128):
    for y in range(0,256,88):
        world.paste(bush,(lane,y))
        world.paste(bush.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(lane+106,y+44))
    for x in (32,72):
        world.paste(puddle,(lane+x-4,36))
d = ImageDraw.Draw(world)
for x in (32,72):
    for lane in (0,128):
        d.ellipse((lane+x+5,202,lane+x+10,207),fill=3)
        d.ellipse((lane+x+6,203,lane+x+9,206),fill=13)
raw = list(world.getdata())
(out/'visual-world.bin').write_bytes(bytes(raw[i]*16+raw[i+1] for i in range(0,len(raw),2)))
# Arcade course rebuilt from MAME (tools/stitch_ironman.py and
# tools/build_ironman_course.py): two 2048-line halves side by side.
ironman=Path('build/ironman')
land_bytes=(ironman/'land.bin').read_bytes()
assert len(land_bytes)==256*2048//2
(out/'visual-land.bin').write_bytes(land_bytes)

# Collision cells come from the arcade map: 512 rows of 16 cells over the
# whole course (0 free, 1 puddle, 2 mine, 3 rock) at bank offset 0x0000, and
# 256 rows of bridge surfaces (1 wading water, 2 deck) at 0x2000.
course=json.loads((art/'course.json').read_text())
collision=(ironman/'collision.bin').read_bytes()
surfaces=(ironman/'surfaces.bin').read_bytes()
assert len(collision)==512*16 and len(surfaces)==256*16
(out/'visual-land-collision.bin').write_bytes(collision)
(out/'visual-land-surfaces.bin').write_bytes(surfaces)

# River logs as in MAME: one log per row, every 80 lines, all drifting right
# across the river; each row has its own phase. Progress values put the log
# where the arcade has it (rows 3176, 3256, 3336 of the arcade course).
logs=[(2795,0),(2875,50),(2955,100)]
river_lines=['log_positions:']
for progress,phase in logs:
    river_lines.extend((f'        dw {progress}',f'        db {phase}'))
(out/'visual-river-layout.inc').write_text('\n'.join(river_lines)+'\n')


# Separate exit/finish section, using the sand and foliage of the arcade.
# Its 512-line page prevents the final stretch repeating the opening terrain.
finish=Image.new('P',(256,512),1)
finish_tree=Image.open(art/'finish-vegetation.png').convert('RGBA')
finish_tree_pixels=indexed(finish_tree)
finish_tree_mask=finish_tree.getchannel('A')
for lane in (0,128):
    for y in range(0,512,24):
        for x in range(0,120,24):
            finish.paste(sand,(lane+x,y))
    finish.paste(finish_tree_pixels,(lane+85,311),finish_tree_mask)
    draw=ImageDraw.Draw(finish)
    for x in range(0,120,5):
        draw.line((lane+x,376,lane+min(x+2,119),376),fill=8)
raw=list(finish.getdata())
# Banks 24-27 (the old finish picture) hold the arcade runner poses at VRAM
# y=3584 in 32x48 cells with the feet on the bottom row. The layout mirrors
# the old 24x32 actor atlas (rows 0/32/64/96 become 0/48/96/144), so the
# Z80 keeps its pose selection and only translates the cell; the waist-deep
# wading poses (not seen in MAME) use the arcade runner's upper body with the
# swimmer's foam in row 192.
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
import extract_ironman_sprites as arcade
actors_arcade=Image.new('P',(256,368),0)
def cell(image,x,y,w=32,h=48,place='bottom'):
    mask=image.getchannel('A').point(lambda a:255 if a else 0)
    left=x+(w-image.width)//2
    top=y+h-image.height if place=='bottom' else y+(h-image.height)//2
    actors_arcade.paste(indexed(image),(left,top),mask)
def player_and_cpu(name,x,y,**kw):
    cell(arcade.actor(name,False),x,y,**kw)
    cell(arcade.actor(name,True),x+32,y,**kw)
player_and_cpu('run_a',0,0); player_and_cpu('run_b',0,48); player_and_cpu('stand',0,96)
player_and_cpu('fallen',64,0); player_and_cpu('fallen',64,48); player_and_cpu('run_c',64,96)
player_and_cpu('swim_a',128,0); player_and_cpu('swim_b',128,48); player_and_cpu('run_b',128,96)
# Player-only directional poses (left, right, down) in row 144.
turn_a=arcade.actor('turn_a',False); turn_b=arcade.actor('turn_b',False)
cell(turn_a,0,144); cell(turn_b.transpose(Image.Transpose.FLIP_LEFT_RIGHT),32,144)
cell(turn_a.transpose(Image.Transpose.FLIP_LEFT_RIGHT),64,144); cell(turn_b,96,144)
for index,name in enumerate(('run_a','run_c','run_a','run_c')):
    image=arcade.actor(name,False)
    if index>=2: image=image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    cell(image,128+index*32,144)
# Waist-deep wading (front bank), matched against the arcade by the bridge
# (videos 2026-11-12 19-13-48 and 2026-11-13): the sprite is never turned.
# Forward: codes 8 and 12, the back of the head and the arms stroking (row
# 192: player x 0/32, CPU x 64/96); back: codes 24 and 28, the face towards
# the camera (row 192 x 128/160). Sideways and still: code 0, as drawn for
# the right (row 288 x 128/160) and mirrored for the left (row 288 x 64/96).
for cpu,x in ((False,0),(True,64)):
    for frame,code in enumerate((8,12)):
        cell(arcade.front(code,None,cpu),x+frame*32,192)
side=arcade.front(0,None,False)
for frame,code in enumerate((24,28)):
    cell(arcade.front(code,None,False),128+frame*32,192)
    cell(side.transpose(Image.Transpose.FLIP_LEFT_RIGHT),64+frame*32,288)
    cell(side,128+frame*32,288)
# Goal (row 240): turning round, panting, and the player's raised arm.
for index,image in enumerate((arcade.actor('turn_goal_a',False),arcade.actor('turn_goal_b',False),
                              arcade.front(4,180,False),arcade.front(20,181,False),
                              arcade.front(136,181,False),arcade.front(144,181,False),
                              arcade.actor('turn_goal_a',True),arcade.actor('turn_goal_b',True))):
    cell(image,index*32,240)
cell(arcade.front(4,180,True),0,288); cell(arcade.front(20,181,True),32,288)
# Labels at y=336 (10 rows each), as written by the arcade at the goal.
labels=ImageDraw.Draw(actors_arcade)
draw_text(labels,0,336,'PLAYER 1',8,scale=2,shadow=shadow_pen(pal))
draw_text(labels,64,336,'(NICK)',8,scale=2,shadow=shadow_pen(pal))
draw_text(labels,112,336,'YOU MADE IT',8,scale=2,shadow=shadow_pen(pal))
draw_text(labels,200,336,'GOAL',8,scale=2,shadow=shadow_pen(pal))
draw_text(labels,0,348,'CPU (JOE)',8,scale=2,shadow=shadow_pen(pal))
# Lost by the clock (arcade): YOU BLEW IT in red, under PLAYER 1 / (NICK).
draw_text(labels,0,358,'YOU BLEW IT',13,scale=2,shadow=shadow_pen(pal))
# Red 1P of the single game score (src/step3_visual.asm draw_score), x 96-111.
draw_text(labels,96,358,'1P',13,scale=2,shadow=shadow_pen(pal))
# Clock separators ':' (x=80) and '.' (x=88), 8x10 like the digits.
labels.rectangle((83,350,84,351),fill=8); labels.rectangle((83,354,84,355),fill=8)
labels.rectangle((91,356,92,357),fill=8)
raw=list(actors_arcade.getdata())
(out/'visual-finish.bin').write_bytes(bytes(raw[i]*16+raw[i+1] for i in range(0,len(raw),2)))

water = Image.new('P',(256,256),15)
water_src = Image.open(art/'water.png').convert('RGB')
# Enhance the subtle video colours before reducing to the three water pens.
water_src.putdata([(r,max(0,min(255,160+(g-160)*3)),max(0,min(255,155+(b-155)*2)))
                   for r,g,b in water_src.getdata()])
water_tile = indexed(water_src)
for y in range(0,256,48):
    for x in range(0,256,24):
        water.paste(water_tile,(x,y))
raw = list(water.getdata())
# Banks 4-5 (the old water picture) now hold a 256x256 atlas of arcade river
# objects at VRAM y=1024 (tools/extract_ironman_sprites.py): the free boat and
# its mirror (the arcade rocks it by flipping) at x=0/32, and the two log
# frames at x=64/96.
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
import extract_ironman_sprites as arcade
objects=Image.new('P',(256,256),0)
def put(image,x,y):
    mask=image.getchannel('A').point(lambda a:255 if a else 0)
    objects.paste(indexed(image),(x,y),mask)
boat_image=arcade.boat()
put(boat_image,0,0)
put(boat_image.transpose(Image.Transpose.FLIP_LEFT_RIGHT),32,0)
put(arcade.log(144),64,0)
put(arcade.log(148),96,0)
# Mine explosion, ten 32x16 frames at x=128+32*(f%4), y=16*(f//4).
for frame in range(10):
    put(arcade.mine_blast(frame),128+32*(frame%4),16*(frame//4))
# Boarding (five frames over the boat, 48x64): player row 128, CPU row 192.
for cpu,y in ((False,128),(True,192)):
    for frame in range(5):
        image=arcade.boarding(frame,cpu)
        objects.paste(indexed(image),(frame*48,y),image.getchannel('A').point(lambda a:255 if a else 0))
# Rowing (boat and rower, 48x64) in the objects atlas row 64: player at
# x=0/48, CPU at x=96/144.
for cpu,x in ((False,0),(True,96)):
    for frame,name in enumerate(('row_a','row_b')):
        image=arcade.actor(name,cpu)
        mask=image.getchannel('A').point(lambda a:255 if a else 0)
        objects.paste(indexed(image),(x+frame*48+(48-image.width)//2,64+(64-image.height)//2),mask)
raw=list(objects.getdata())
(out/'visual-water.bin').write_bytes(bytes(raw[i]*16+raw[i+1] for i in range(0,len(raw),2)))
atlas = Image.new('P',(256,64),0)
d = ImageDraw.Draw(atlas)
for left,shirt in ((0,4),(16,5)):
    d.rectangle((left+6,1,left+9,4),fill=6)
    d.rectangle((left+4,5,left+11,9),fill=shirt)
    d.line((left+3,5,left+1,9),fill=6,width=2)
    d.line((left+12,5,left+14,9),fill=6,width=2)
    d.rectangle((left+5,10,left+7,15),fill=7)
    d.rectangle((left+9,10,left+11,15),fill=7)
for left,shirt in ((32,4),(48,5)):
    d.rectangle((left+4,5,left+7,8),fill=6)
    d.rectangle((left+3,9,left+9,12),fill=shirt)
    d.line((left+4,11,left+1,15),fill=6,width=2)
    d.rectangle((left+8,12,left+14,15),fill=7)
for left,shirt in ((64,4),(80,5)):
    d.ellipse((left+5,3,left+10,8),fill=6)
    d.rectangle((left+5,9,left+10,12),fill=shirt)
    d.line((left+4,9,left+1,12),fill=6,width=2)
    d.line((left+11,9,left+14,12),fill=6,width=2)
    d.line((left+2,15,left+13,15),fill=8)
for left,shirt in ((96,4),(112,5)):
    d.polygon(((left+7,0),(left+13,4),(left+13,12),(left+7,15),(left+2,12),(left+2,4)),fill=11)
    d.rectangle((left+5,5,left+10,10),fill=shirt)
    d.rectangle((left+6,3,left+9,5),fill=6)
# Unoccupied boat for each viewport.
d.polygon(((135,0),(141,4),(141,12),(135,15),(130,12),(130,4)),fill=11)
# Arcade-derived log and rock. Their alpha masks preserve the foam/outline.
for filename, position in (('river-log.png',(176,32)),('river-rock.png',(216,32))):
    sprite=Image.open(art/filename).convert('RGBA')
    atlas.paste(indexed(sprite),position,sprite.getchannel('A').point(lambda a:255 if a>=128 else 0))
blast = Image.open(art/'mine-blast.png').convert('RGBA')
blast_mapped = indexed(blast)
blast_mask = blast.getchannel('A').point(lambda a:255 if a>=128 else 0)
atlas.paste(blast_mapped,(144,32),blast_mask)
# Waist-deep bridge water poses occupy otherwise unused atlas row 48.
for index in range(2):
    pose=Image.open(art/f'wade-{index}.png').convert('RGBA')
    for cpu in (False,True):
        image=pose.copy()
        if cpu:
            image.putdata([(104,160,128,a) if r>g*1.35 and r>150 and 55<g<180 and b<90 else (r,g,b,a)
                           for r,g,b,a in image.getdata()])
        atlas.paste(indexed(image),(index*32+(64 if cpu else 0),48),
                    image.getchannel('A').point(lambda a:255 if a>=128 else 0))

draw_text(d,160,0,'YOU MADE IT',8)
draw_text(d,160,8,'CPU WINS',8)
digits = ('111101101101111','010110010010111','111001111100111',
          '111001111001111','101101111001001','111100111001111',
          '111100111101111','111001001001001','111101111101111',
          '111101111001111')
for n, glyph in enumerate(digits):
    for y in range(5):
        for x in range(3):
            if glyph[y*3+x] == '1':
                d.rectangle((n*8+x*2,16+y*2,n*8+x*2+1,17+y*2),fill=8)
draw_text(d,96,16,'TIME UP',8)
draw_text(d,96,24,'BONUS',8)
draw_text(d,136,24,'SEC',8)
power=('11110/10001/10001/11110/10000/10000',
       '01110/10001/10001/10001/10001/01110',
       '10001/10001/10101/10101/11011/10001',
       '11111/10000/11110/10000/10000/11111',
       '11110/10001/11110/10100/10010/10001')
for offset,colour in ((1,3),(0,13)):
    for index,pattern in enumerate(power):
        for y,line in enumerate(pattern.split('/')):
            for x,bit in enumerate(line):
                if bit=='1': d.point((160+index*7+x+offset,16+y+offset),fill=colour)
# Second diagnostic pose for running, swimming and rowing.
for left, shirt in ((0,4),(16,5)):
    d.rectangle((left+6,33,left+9,36),fill=6)
    d.rectangle((left+4,37,left+11,41),fill=shirt)
    d.line((left+3,37,left+1,34),fill=6,width=2)
    d.line((left+12,37,left+14,41),fill=6,width=2)
    d.line((left+6,42,left+3,47),fill=7,width=3)
    d.line((left+9,42,left+12,47),fill=7,width=3)
for left, shirt in ((64,4),(80,5)):
    d.ellipse((left+5,35,left+10,40),fill=6)
    d.rectangle((left+5,41,left+10,44),fill=shirt)
    d.line((left+4,40,left+1,37),fill=6,width=2)
    d.line((left+11,40,left+14,37),fill=6,width=2)
    d.line((left+1,47,left+14,47),fill=8)
for left, shirt in ((96,4),(112,5)):
    d.polygon(((left+7,32),(left+13,36),(left+13,44),(left+7,47),(left+2,44),(left+2,36)),fill=11)
    d.rectangle((left+5,37,left+10,42),fill=shirt)
    d.rectangle((left+6,35,left+9,37),fill=6)
    d.line((left+2,39,left,45),fill=14)
# Actor poses occupy a separate 256x64 atlas at 24x32 pixels each. The UI,
# logs and empty boats keep their existing 16x16 atlas and coordinates.
actors = Image.new('P',(256,128),0)
ad = ImageDraw.Draw(actors)
def paste_pose(filename, x, y, recolour=None, flip=False):
    image = Image.open(art/filename).convert('RGBA')
    if flip:
        image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if recolour:
        data=[]
        for r,g,b,a in image.getdata():
            if recolour == 'orange' and g>r*1.08 and g>b*1.05 and g>50:
                r,g,b = 232,128,0
            elif recolour == 'green' and r>g*1.35 and r>150 and 55<g<170 and b<80:
                r,g,b = 104,160,128
            data.append((r,g,b,a))
        image.putdata(data)
    mapped = indexed(image)
    mask = image.getchannel('A').point(lambda a: 255 if a >= 128 else 0)
    if image.size != (24,32):
        raise ValueError(f'{filename}: expected 24x32, got {image.size}')
    actors.paste(mapped,(x,y),mask)

for y,flip in ((0,False),(32,True)):
    index=1 if flip else 0
    paste_pose(f'run-cycle-player-{index}.png',0,y)
    paste_pose(f'run-cycle-cpu-{index}.png',32,y)
    paste_pose('swimmer-player.png',128,y,flip=flip)
    paste_pose('swimmer-cpu.png',160,y,flip=flip)
    paste_pose('boat-player.png',192,y,flip=flip)
    paste_pose('boat-player.png',224,y,recolour='green',flip=flip)
    paste_pose('runner-fallen.png',64,y)
    paste_pose('runner-fallen.png',96,y,recolour='green')
paste_pose('runner-standing.png',0,64)
paste_pose('runner-standing.png',32,64,recolour='green')
for index,x in ((2,64),(3,128)):
    paste_pose(f'run-cycle-player-{index}.png',x,64)
    paste_pose(f'run-cycle-cpu-{index}.png',x+32,64)
# Directional poses captured from the arcade: left/right profiles and front.
paste_pose('run-side-0.png',0,96)
paste_pose('run-side-1.png',32,96,flip=True)
paste_pose('run-side-0.png',64,96,flip=True)
paste_pose('run-side-1.png',96,96)
paste_pose('run-front-0.png',128,96)
paste_pose('run-front-1.png',160,96)
paste_pose('run-front-0.png',192,96,flip=True)
paste_pose('run-front-1.png',224,96,flip=True)
pixels = list(atlas.getdata())
(out/'visual-atlas.bin').write_bytes(bytes(pixels[i]*16+pixels[i+1] for i in range(0,len(pixels),2)))
pixels = list(actors.getdata())
(out/'visual-actors.bin').write_bytes(bytes(pixels[i]*16+pixels[i+1] for i in range(0,len(pixels),2)))
