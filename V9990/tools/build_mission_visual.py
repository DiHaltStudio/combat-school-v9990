#!/usr/bin/env python3
"""Build an isolated first-room movement experiment using arcade captures."""
from pathlib import Path
from PIL import Image,ImageDraw
from impact_flash import draw_impact_flash
from mission_chain_assets import build_chain
import sys
# "integrated": the mission inside the game MegaROM (tools/build_megarom.py),
# its banks moved to BANK_BASE.. and GAME OVER through the game's common
# routine; writes build/mission/integrated.asm instead of visual.asm.
INTEGRATED=len(sys.argv)>1 and sys.argv[1]=='integrated'
BANK_BASE=34 if INTEGRATED else 0

p=Path('build/mission');p.mkdir(parents=True,exist_ok=True)
a=Path('assets/mission')
names=('idle','attack3','jump2','airkick','walk1','walk2','walk3','walk4',
       'enemy-walk1','enemy-walk2','enemy-walk3','enemy-hit','enemy-fall','enemy-down',
       'enemy-throw-40','enemy-throw-44','enemy-throw-48',
       'player-grab2','player-grab3','orange-walk1','orange-walk2',
       'orange-hit','orange-knee','orange-fall','orange-down')
field=Image.open(a/'field.png').convert('RGB')
course=Image.open(a/'course-expanded.png').convert('RGB')
# Preserve the existing route at +256; the captured final viewport begins
# at x=109, so the unused prefix is never shown.
final=Image.open(a/'course-next-reference.png').convert('RGB')
expanded=Image.new('RGB',(2048,212))
expanded.paste(final.crop((0,0,147,212)),(109,0))
expanded.paste(course,(256,0));course=expanded
course.save(p/'complete-course-reference.png')
hud=Image.open(a/'damage-hud.png').convert('RGB')
# The capture contains the arcade's backdrop colour behind the damage cells.
# In the mission the HUD sits on black; retain the cells and lettering only.
hud.putdata([(0,0,0) if rgb in ((132,132,132),(49,82,99),(66,99,123)) else rgb
             for rgb in hud.getdata()])
assert course.height==212 and 256<course.width<=2048
poses=[Image.open(a/(n+'.png')).convert('RGBA') for n in names]
# One palette for the whole mission (B1 has a single 16-colour palette per
# screen, and the doorways show two rooms at once). tools/mission_palette.py
# computes it with weighted k-means over the whole course and the actors;
# black (0) and the orange shirt (15) are fixed. Per-zone RMS error against
# the arcade captures, previous median cut -> this palette: brick room
# 25.5 -> 20.1, industrial 19.1 -> 10.7, pink room 13.9 -> 14.0, actors
# 30.3 -> 23.9, chain assailant and boss 34.0 -> 29.7.
MISSION_PALETTE=[(0,0,0),(32,152,160),(136,0,104),(32,64,32),(48,32,32),
                 (0,88,136),(56,88,104),(192,136,136),(176,160,160),(0,96,96),
                 (216,200,168),(104,120,96),(248,136,120),(112,64,8),
                 (144,88,96),(232,112,24)]
pal=[v for rgb in MISSION_PALETTE[1:] for v in rgb]
ref=Image.new('P',(1,1));ref.putpalette([0,0,0]+pal+[0]*(768-48))
colour=min(range(1,16),key=lambda i:sum((ref.getpalette()[3*i+j]-v)**2 for j,v in enumerate((240,0,176))))
(p/'palette.bin').write_bytes(bytes(v>>3 for v in ref.getpalette()[:48]))
def pack(im):
    values=list(im.getdata())
    return bytes(values[i]*16+values[i+1] for i in range(0,len(values),2))
background=field.quantize(palette=ref,dither=Image.Dither.NONE)
raw_field=pack(background);assert len(raw_field)==27136
assert course.width%2==0
(p/'course-reference.bin').write_bytes(pack(course.quantize(palette=ref,dither=Image.Dither.NONE)))
atlas=Image.new('P',(256,512),0)
extra=Image.new('P',(256,480),0)
for name,pose in zip(names,poses):
    # Every source frame shares a bottom anchor to avoid wobbling feet.
    bbox=pose.getbbox();cropped=pose.crop(bbox)
    anchored=Image.new('RGBA',(64,64));anchored.alpha_composite(cropped,((64-cropped.width)//2,64-cropped.height))
    # Render only the central columns below; fail the build if a new pose
    # extends outside that window rather than silently cutting off pixels.
    left,_,right,_=anchored.getbbox()
    inset=15 if name.startswith('enemy-throw-') else 17 if name.startswith(('enemy-','orange-')) else 0 if name.startswith('player-grab') else 8
    assert left>=inset and right<=64-inset,(name,anchored.getbbox())
    if name.startswith(('enemy-','orange-')) and not name.startswith('enemy-throw-'):assert anchored.getbbox()[1]>=8,(name,anchored.getbbox())
    img=anchored.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE)
    mirror=anchored.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    mi=mirror.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE)
    # The walk, idle and jump captures face left; the extended kick capture
    # faces right. The shared renderer expects right first, then left.
    if name in ('idle','attack3','jump2','airkick'):
        x={'idle':0,'attack3':64,'jump2':128,'airkick':192}[name]
        if name=='attack3':
            atlas.paste(img,(x,0),anchored.getchannel('A'));atlas.paste(mi,(x,64),mirror.getchannel('A'))
        else:
            atlas.paste(mi,(x,0),mirror.getchannel('A'));atlas.paste(img,(x,64),anchored.getchannel('A'))
    if name in ('walk1','walk2'):
        x=0 if name=='walk1' else 64
        atlas.paste(mi,(x,192),mirror.getchannel('A'));atlas.paste(img,(x,256),anchored.getchannel('A'))
    if name in ('walk1','walk2','walk3','walk4'):
        x=64*(int(name[-1])-1)
        extra.paste(mi,(x,128),mirror.getchannel('A'));extra.paste(img,(x,192),anchored.getchannel('A'))
    if name in ('orange-walk1','orange-walk2'):
        x=64*(int(name[-1])-1)
        extra.paste(mi,(x,0),mirror.getchannel('A'));extra.paste(img,(x,64),anchored.getchannel('A'))
    if name in ('orange-hit','orange-knee'):
        x=128 if name=='orange-hit' else 192
        extra.paste(mi,(x,0),mirror.getchannel('A'));extra.paste(img,(x,64),anchored.getchannel('A'))
    if name in ('orange-fall','orange-down'):
        x=0 if name=='orange-fall' else 64
        extra.paste(mi,(x,256),mirror.getchannel('A'));extra.paste(img,(x+128,256),anchored.getchannel('A'))
    if name in ('player-grab2','player-grab3'):
        x=128 if name=='player-grab2' else 192
        atlas.paste(mi,(x,192),mirror.getchannel('A'));atlas.paste(img,(x,256),anchored.getchannel('A'))
    if name.startswith('enemy-'):
        # All of these arcade captures face right; reflected poses face left.
        if name.startswith('enemy-throw-'):
            x,y={'enemy-throw-40':(0,352),'enemy-throw-44':(128,352),'enemy-throw-48':(0,416)}[name]
            extra.paste(mi,(x,y),mirror.getchannel('A'));extra.paste(img,(x+64,y),anchored.getchannel('A'))
        elif name=='enemy-walk3':
            atlas.paste(img,(128,384),anchored.getchannel('A'));atlas.paste(mi,(192,384),mirror.getchannel('A'))
        elif name=='enemy-down':
            atlas.paste(img,(0,384),anchored.getchannel('A'));atlas.paste(mi,(64,384),mirror.getchannel('A'))
        else:
            x={'enemy-walk1':0,'enemy-walk2':64,'enemy-hit':128,'enemy-fall':192}[name]
            atlas.paste(img,(x,128),anchored.getchannel('A'));atlas.paste(mi,(x,320),mirror.getchannel('A'))
atlas.paste(hud.quantize(palette=ref,dither=Image.Dither.NONE),(0,448))
# Same shape as the instructor fight, mapped to the mission palette.
pen=ImageDraw.Draw(atlas)
def closest(rgb):
    return min(range(1,16),key=lambda i:sum((ref.getpalette()[3*i+j]-v)**2 for j,v in enumerate(rgb)))
draw_impact_flash(pen,96,488,closest((240,152,24)),closest((255,255,255)))
draw_impact_flash(pen,112,488,closest((200,48,208)),closest((255,255,255)))
# Single game score (src/mission_enemy.asm): 8x8 cells in atlas row 464
# (VRAM y 1232, always loaded): red 1 and P at x 0 and 8, white digits
# 0-9 from x 16, in a 5x7 font with an empty top row. Row 472, x 128..199
# (VRAM y 1240) stays empty: the score is composed there.
font={'0':'01110100011001110101110011000101110','1':'00100011000010000100001000010001110',
 '2':'01110100010000100010001000100011111','3':'11111000100010000010000011000101110',
 '4':'00010001100101010010111110001000010','5':'11111100001111000001000011000101110',
 '6':'00110010001000011110100011000101110','7':'11111000010001000100010000100001000',
 '8':'01110100011000101110100011000101110','9':'01110100011000101111000010001001100',
 'P':'11110100011000111110100001000010000'}
pen=ImageDraw.Draw(atlas)
for i,ch in enumerate('1P0123456789'):
    ink=closest((240,8,8)) if i<2 else closest((255,255,255))  # not colour: the damage cells use it
    for y in range(7):
        for x in range(5):
            if font[ch][y*5+x]=='1': pen.point((i*8+1+x,465+y),fill=ink)
# Draw a compact knife sprite in both directions using the shared palette.
pen=ImageDraw.Draw(extra)
for left,x in ((False,0),(True,16)):
    # Narrow, pointed blade and small guard, based on the arcade close-up.
    blade=closest((224,224,208));shade=closest((128,152,136))
    handle=closest((80,56,32))
    def px(dx,y,color):
        pen.point((x+(15-dx if left else dx),y),fill=color)
    for dx in range(5,13): px(dx,323,blade)
    for dx in range(5,11): px(dx,324,shade)
    px(13,323,blade)
    for dx in (2,3,4): px(dx,324,handle)
    px(4,322,shade);px(4,323,shade)
# Flying bottle captured from the arcade sprite; keep both flight directions.
bottle=Image.open(a/'molotov-flight.png').convert('RGBA')
assert bottle.size==(16,16)
for x,img in ((128,bottle),(144,bottle.transpose(Image.Transpose.FLIP_LEFT_RIGHT))):
    extra.paste(img.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE),
                (x,416),img.getchannel('A'))
# Ground fire combines two arcade sprites into a single 32x48 V9990 copy.
fire=Image.open(a/'molotov-fire.png').convert('RGBA')
assert fire.size==(32,48)
extra.paste(fire.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE),
            (160,416),fire.getchannel('A'))
# A second frame reuses the original fire, reflected horizontally. It uses
# the adjacent free slot and keeps the same 32x48 copy cost at runtime.
fire_alt=fire.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
extra.paste(fire_alt.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE),
            (192,416),fire_alt.getchannel('A'))
raw=pack(atlas)
(p/'atlas-reference.bin').write_bytes(raw)
(p/'extra-reference.bin').write_bytes(pack(extra))
def rle(data):
    encoded=bytearray();i=0
    while i<len(data):
        j=i+1
        while j<len(data) and data[j]==data[i] and j-i<255:j+=1
        encoded.extend((j-i,data[i]));i=j
    encoded.append(0)
    return encoded
def bank(data):
    encoded=rle(data)
    assert len(encoded)<=16384,len(encoded)
    return encoded+bytes([255])*(16384-len(encoded))
(p/'field-rle-bank.bin').write_bytes(bank(raw_field))
(p/'atlas0-rle-bank.bin').write_bytes(bank(raw[:32768]))
(p/'atlas1-rle-bank.bin').write_bytes(bank(raw[32768:]))
chunks=(course.width+255)//256
assert chunks<=8, 'room strips must fit in the two reserved VRAM ranges'
chain_tails=build_chain(a,p,ref)
packed_course=bytearray();course_locations=[]
for i in range(chunks):
    chunk=Image.new('RGB',(256,212))
    chunk.paste(course.crop((i*256,0,min((i+1)*256,course.width),212)),(0,0))
    indexed=Image.new("P",(256,252),0);indexed.putpalette(ref.getpalette())
    indexed.paste(chunk.quantize(palette=ref,dither=Image.Dither.NONE),(0,0))
    indexed.paste(chain_tails[i],(0,212))
    raw_chunk=pack(indexed)
    if len(packed_course)&1:packed_course.append(255)
    course_locations.append((3+len(packed_course)//16384,len(packed_course)%16384))
    packed_course.extend(rle(raw_chunk))
# Nine precomposed HUD states cost one V9990 copy per frame, irrespective
# of the number of filled damage cells. The original separators are retained.
hud_row=hud.quantize(palette=ref,dither=Image.Dither.NONE)
damage_huds=Image.new('P',(256,16*9+8*9));damage_huds.putpalette(ref.getpalette())
for damage in range(9):
    row=hud_row.copy()
    pixels=row.load()
    for cell in range(damage):
        left=151 if cell==0 else 160+(cell-1)*8
        width=8 if cell==0 else 7
        for yy in range(8,16):
            for xx in range(left,left+width):pixels[xx,yy]=colour
    damage_huds.paste(row,(0,16*damage))
# Guardian damage uses the left eight complete cells, retaining the borders.
for damage in range(9):
    row=hud_row.crop((0,8,256,16));pixels=row.load()
    for cell in range(damage):
        left=97 if cell==0 else 89-(cell-1)*8
        width=8 if cell==0 else 7
        for yy in range(8):
            for xx in range(left,left+width):pixels[xx,yy]=15
    damage_huds.paste(row,(0,144+8*damage))

if len(packed_course)&1:packed_course.append(255)
damage_mapper=3+len(packed_course)//16384
damage_offset=len(packed_course)%16384
packed_course.extend(rle(pack(damage_huds)))
if len(packed_course)&1:packed_course.append(255)
extra_mapper=3+len(packed_course)//16384
extra_offset=len(packed_course)%16384
packed_course.extend(rle(pack(extra)))
hang=Image.new('P',(256,208),0)
hang.putpalette(ref.getpalette())
for i,name in enumerate(('hang1','hang2')):
    pose=Image.open(a/(name+'.png')).convert('RGBA')
    assert pose.size==(64,80)
    # Both arcade poses share the same centre; the source captures have
    # different transparent margins and must not jump when changing frame.
    box=pose.getbbox()
    anchored=Image.new('RGBA',(64,80))
    anchored.alpha_composite(pose.crop(box),((64-(box[2]-box[0]))//2,box[1]))
    pose=anchored
    for facing in range(2):
        img=pose if facing==0 else pose.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        hang.paste(img.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE),
                   (64*i+128*facing,0),img.getchannel('A'))
# One captured orange release pose and its mirror after the pipe poses.
throw=Image.open(a/'orange-throw.png').convert('RGBA')
box=throw.getbbox();crop=throw.crop(box)
anchored=Image.new('RGBA',(64,64))
anchored.alpha_composite(crop,((64-crop.width)//2,64-crop.height))
assert anchored.getbbox()[0]>=17 and anchored.getbbox()[2]<=47
for x,img in ((0,anchored),(64,anchored.transpose(Image.Transpose.FLIP_LEFT_RIGHT))):
    hang.paste(img.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE),
               (x,80),img.getchannel('A'))
for name,x in [('chain-idle',0),('president',128)]:
    pose=Image.open(a/(name+'.png')).convert('RGBA')
    box=pose.getbbox();crop=pose.crop(box)
    anchored=Image.new('RGBA',(64,64))
    anchored.alpha_composite(crop,((64-crop.width)//2,64-crop.height))
    for dx,img in [(x,anchored),(x+64,anchored.transpose(Image.Transpose.FLIP_LEFT_RIGHT))]:
        hang.paste(img.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE),(dx,144),img.getchannel('A'))
(p/'hang-reference.bin').write_bytes(pack(hang))
if len(packed_course)&1:packed_course.append(255)
hang_mapper=3+len(packed_course)//16384
hang_offset=len(packed_course)%16384
packed_course.extend(rle(pack(hang)))
# Screens before the mission (src/mission_prelude.asm): RLE streams that
# may cross into the next bank, like the room strips.
import mission_prelude_data
import build_image_pack
build_image_pack.MIN_REPEAT=3          # loaded once, between black frames
prelude_locations={}
prelude_shared={}
for label,data in mission_prelude_data.streams():
    if data in prelude_shared:
        prelude_locations[label]=prelude_shared[data]
        continue
    if 16384-len(packed_course)%16384<3:
        packed_course.extend(bytes([255])*(16384-len(packed_course)%16384))
    prelude_locations[label]=prelude_shared[data]=(BANK_BASE+3+len(packed_course)//16384,0x8000+len(packed_course)%16384)
    packed_course.extend(build_image_pack.encode(data,len(packed_course)))
prelude_tables=mission_prelude_data.tables(prelude_locations.__getitem__,('attention','mansion'))
# The arcade ending (src/mission_ending.asm): its mansion streams above, its
# code, texts and tables in the bank after the course banks, at page 2.
ending_tables=mission_prelude_data.tables(prelude_locations.__getitem__,('ending',))
packed_course.extend(bytes([255])*((-len(packed_course))%16384))
(p/'course-banks.bin').write_bytes(packed_course)
ending_bank=BANK_BASE+3+len(packed_course)//16384

# Frozen mission baseline, derived from Step 7 before its independent changes.
# Do not import the live Step 7 file: its RAM map and sprite atlas differ.
source=Path('src/mission_base.asm').read_text()
init=source[:source.index('loop:')]
controls=source[source.index('controls:'):source.index('instructor_ai:')]
draw=source[source.index('\ndraw:\n')+1:source.index('.player_result_ready:')]
draw+=source[source.index('.player_result_ready:'):source.index('        ld hl,actor_template\n        call copy_command',source.index('.player_result_ready:'))]
player_command='''        ld hl,0xc300
        call command
'''
assert draw.count(player_command)==2
prefix,command=draw.rsplit(player_command,1)
draw=prefix+'''        ld a,(0xc823)
        or a
        jr nz,.player_copy_ready  ; reaction poses may use the full 64px
        ld a,(0xc856)
        or a
        jr z,.player_copy_ready
        ; The normal anchored player poses occupy only the central 48 columns.
        ld hl,0xc300
        ld a,(hl)
        add a,8
        ld (hl),a
        ld hl,0xc304
        ld a,(hl)
        add a,8
        ld (hl),a
        ld a,48
        ld (0xc308),a
        ld a,(0xc804)
        or a
        jr z,.player_copy_ready
        ; Both airborne poses leave the top 16 atlas rows transparent.
        ld hl,0xc302
        ld a,(hl)
        add a,16
        ld (hl),a
        ld hl,0xc306
        ld a,(hl)
        add a,16
        ld (hl),a
        ld a,48
        ld (0xc30a),a
.player_copy_ready:
        ld hl,0xc300
        call command
'''+command
draw_head,draw_tail=draw.rsplit('        ld hl,0xc300\n        call command\n',1)
draw=draw_head+'        call mission_hang_draw\n        ld hl,0xc300\n        call command\n'+draw_tail
draw+='        call mission_draw_impact\n        call mission_door_front\n        ret\n'
wait=source[source.index('.wait_end:'):source.index('result_input:')]
# Finish an ongoing blank, then present only after all V9990 commands have
# finished and a fresh blank begins. This avoids partial-page scanout.
wait=wait.replace('''        jr nz,.wait_end
.wait_start:
''','''        jr nz,.wait_end
.wait_last_command:
        in a,(0x65)
        rrca
        jr c,.wait_last_command
.wait_start:
''',1)
tail=source[source.index('copy_command:'):]
tail=tail[:tail.index('        incbin "../build/step7/ending.bin"')]
loop='loop:\n        call controls\n        call draw\n'+wait
source=init+loop+controls+draw+tail
source=source.replace('loop:\n', '        call mission_init_top\nloop:\n',1)

source=source.replace('../build/step7/','')
needle='        ; Mission atlas at y=768; the obsolete initial bitmap is omitted.\n'
assert source.count(needle)==1
source=source.replace(needle,'''        call mission_prelude
        call psg_stop           ; the driver only plays the effects; the music:
        call mission_music_start ; song 8 as register writes (mission_music_tick)
        call psg_defer_on       ; ticks after each drawn frame
        ld hl,0
        ld (MISSION_TICKS),hl   ; none owed, no tick last frame
        ld (MISSION_SPARE),hl
        ld a,13
        out (0x64),a
        ld hl,settings
        ld bc,0x0863
        otir
        ld hl,palette
        ld bc,0x3061
        otir
'''+needle,1)
camera_max=course.width-256
# The extended reconstruction starts 206 pixels before the previous one.
course_shift=206
camera_start=552+course_shift+768+256
# Step 7 may change its starting coordinate independently of the mission.
import re
match=re.search(r'        ld hl,0x[0-9a-fA-F]+[^\n]*\n        ld \(0xc800\),hl',source)
assert match, 'missing inherited player initialization'
needle=match.group(0)
assert source.count(needle)==1
course_upload=''
for i in range(chunks):
    address=((1280+256*i) if i<4 else (3072+256*(i-4)))*128
    mapper,offset=course_locations[i]
    course_upload+=f'''        xor a
        out (0x64),a
        out (0x63),a
        ld a,{(address>>8)&255}
        out (0x63),a
        ld a,{(address>>16)&255}
        out (0x63),a
        ld a,{mapper+BANK_BASE}
        ld (0x7000),a
        ld (0xc839),a
        ld hl,{0x8000+offset}
        call upload_rle
'''
course_upload+=f'''        xor a
        out (0x64),a
        out (0x63),a
        ld a,128
        out (0x63),a
        ld a,4                 ; VRAM y=2304, after the four room strips
        out (0x63),a
        ld a,{damage_mapper+BANK_BASE}
        ld (0x7000),a
        ld (0xc839),a
        ld hl,{0x8000+damage_offset}
        call upload_rle
'''
course_upload+=f'''        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        ld a,5                 ; VRAM y=2560: orange, walking and knives
        out (0x63),a
        ld a,{extra_mapper+BANK_BASE}
        ld (0x7000),a
        ld (0xc839),a
        ld hl,{0x8000+extra_offset}
        call upload_rle
'''
course_upload+=f'''        xor a
        out (0x64),a
        out (0x63),a
        ld a,0
        out (0x63),a
        ld a,1                 ; VRAM y=512, hanging and final-room actors
        out (0x63),a
        ld a,{hang_mapper+BANK_BASE}
        ld (0x7000),a
        ld (0xc839),a
        ld hl,{0x8000+hang_offset}
        call upload_rle
'''
source=source.replace(needle,course_upload+f'''        ld hl,{camera_start}
        ld (0xc840),hl
        ld hl,0x6000
        ld (0xc800),hl
        ld a,120
        ld (0xc850),a
        xor a
        ld (0xc851),a
        ld (0xc855),a
        ld (0xc857),a
        ld (0xc858),a
        ld (0xc871),a
        ld (0xc875),a
        ld (0xc878),a
        ld (0xc890),a
        ld (0xc891),a
        ld (0xc895),a
        ld (0xc898),a
        ld (0xc89a),a
        ld (0xc89c),a
        ld (0xc8a2),a
        ld (0xc8ac),a
        ld (0xc8ad),a
        ld (0xc8ae),a
        ld (0xc8c1),a
        ld (0xc8d0),a
        ld (0xc8d4),a
        ld (0xc8d5),a
        ld (0xc8da),a
        ld (0xc8dc),a
        ld (0xc8dd),a
        ld (0xc8de),a
        ld (0xc8df),a
        ld (0xc8e0),a
        ld (0xc8e9),a
        ld (0xc8ed),a
        ld (0xc8f0),a
        ld (0xc8f4),a
        ld (0xc8f5),a
        ld (0xc900),a
        ld (0xc930),a
        ld (0xc990),a
        ld (0xc9b0),a
        ld (0xc9a4),a
        ld (0xc9a5),a
        ld (0xc941),a
        ld (0xc951),a
        ld (0xc961),a
        ld (0xc971),a
        ld (0xc981),a
        ld (0xca02),a
        ld (0xca14),a
        ld (0xca15),a
        ld (0xc86f),a
        ld a,255
        ld (0xc8a6),a
        ld (0xc8a7),a
        ld (0xc8d2),a
        ld (0xc8d3),a
        ld a,(0xc75c)
        cpl
        ld (0xd0bc),a           ; score strip composed on the first frame
        ld a,0xfe
        ld (0xd0c0),a           ; ... with its 1P (src/mission_enemy.asm)
        ld a,120                ; both first attackers enter together in MAME
        ld (0xc870),a
        ld a,8
        ld (0xc856),a''')
source=source.replace('        ld (0xc809),a          ; facing: 0 right, 1 left',
                      '        inc a\n        ld (0xc809),a          ; mission begins facing left\n        xor a',1)
source+='        incbin "course-banks.bin"\n'
# All compressed streams cross mapper boundaries only between complete pairs.
source=source.replace('        ld (0x7000),a\n        ld hl,0x8000',
                      '        ld (0x7000),a\n        ld (0xc839),a\n        ld hl,0x8000')
needle='upload_rle:\n        ld b,(hl)'
assert source.count(needle)==1
source=source.replace(needle,'''upload_rle:
        ld a,h
        cp 0xc0
        jr nz,.read_pair
        ld a,(0xc839)
        inc a
        ld (0xc839),a
        ld (0x7000),a
        ld hl,0x8000
.read_pair:
        ld b,(hl)''')
source=source.replace('        call controls\n        call draw\n','        call controls\n        call mission_camera\n        call mission_enemy_global_tick\n        call mission_enemy_tick\n        call mission_right_tick\n        ld a,(0xc856)\n        or a\n        jr nz,.mission_playing\n        ld a,(0xc823)\n        or a\n        call z,mission_game_over_input\n.mission_playing:\n        call draw\n',1)
source=source.replace('loop:\n        call controls\n', 'loop:\n        call mission_save_position\n        ld a,(0xc8dd)\n        or a\n        call z,controls\n        call mission_hang_update\n        ld a,(0xc8dd)\n        or a\n        call z,mission_crates_tick\n',1)
source=source.replace('        call mission_enemy_global_tick\n', '        call mission_retire_old_bodies\n        call mission_enemy_global_tick\n',1)
source=source.replace('        call mission_enemy_global_tick\n', '        call mission_enemy_global_tick\n        call mission_projectiles_tick\n',1)
source=source.replace('        call mission_projectiles_tick\n        call mission_enemy_tick\n', '        call mission_projectiles_tick\n        call mission_left_tick\n',1)
source=source.replace('        call mission_right_tick\n        ld a,(0xc856)\n', '        call mission_right_tick\n        call mission_third_tick\n        call mission_fourth_tick\n        call mission_knife_pair_tick\n        call mission_late_tick\n        call mission_fire_barrier_tick\n        call mission_later_encounters_tick\n        call mission_waves_tick\n        ld a,(0xc856)\n',1)
needle='''draw:
        ld hl,field_template
        call copy_command
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        call command
'''
assert source.count(needle)==1
source=source.replace(needle,'''draw:
        call mission_background
        call mission_left_draw
        call mission_right_draw
        call mission_third_draw
        call mission_fourth_draw
        call mission_knife_pair_draw
        call mission_late_draw
        call mission_later_encounters_draw
        call mission_projectiles_draw
        call mission_fire_barrier_draw
        call mission_draw_hud
        call mission_boss_hud
''')
scroll='''; The top 16 lines are black in every captured background strip.
; Initialise both drawing pages once; score is drawn over them each frame.
mission_init_top:
        ld hl,mission_ring_clear
        call copy_command
        ld a,40                ; HUD plus the largest coarse ring offset
        ld (0xc30a),a
        ld hl,0xc300
        call raw_command
        ld a,1
        ld (0xc307),a
        ld hl,0xc300
        jp raw_command

; Follow the player while the captured room still extends in that direction.
mission_camera:
        ld a,(0xc981)
        or a
        ret nz                  ; final duel uses a fixed camera
        ld a,(0xc801)
        cp 96
        ret z
        jr nc,.right
        ; At most 2 pixels per update: after a camera hold (chain assailant)
        ; the camera catches up with the player instead of jumping.
        neg
        add a,96
        cp 3
        jr c,.left_step
        ld a,2
.left_step:
        ld e,a
        ld b,a
        ld d,0
        ld hl,(0xc840)
        or a
        sbc hl,de
        ret c
        ; The arcade holds the camera at 159 (ROM 258) until the chain
        ; assailant is down (states 1..4 of C971).
        ld de,109
        ld a,(0xc971)
        dec a
        cp 4
        jr nc,.left_limit
        ld de,258
.left_limit:
        or a
        sbc hl,de
        ret c
        add hl,de
        ld (0xc840),hl
        ld a,(0xc801)
        add a,b
        ld (0xc801),a
        ret
.right:
        sub 96
        cp 3
        jr c,.right_step
        ld a,2
.right_step:
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        push de
        ld de,MISSION_CAMERA_MAX
        or a
        sbc hl,de
        pop de
        ret nc
        ld hl,(0xc840)
        add hl,de
        ld (0xc840),hl
        ld a,(0xc801)
        sub e
        ld (0xc801),a
        ret

; The room is stored in consecutive 256-pixel strips at VRAM y=1280+256*n.
; Draw the end of one strip and, if necessary, the start of the next one.
mission_background:
        ld hl,field_template
        call copy_command
        ; On a page whose camera has not moved, rows 32..63 contain only
        ; background. All mission actors and effects start below that band,
        ; so preserve it and restore rows 64..211 instead. Each page has its
        ; own camera cache because pages are presented alternately.
        ld a,(0xc802)
        or a
        ld hl,0xca10
        ld de,0xca14
        jr z,.background_cache_ready
        inc hl
        inc hl
        inc de
.background_cache_ready:
        ld a,(de)
        or a
        jr z,.background_full
        ld a,(0xc840)
        cp (hl)
        jr nz,.background_full
        inc hl
        ld a,(0xc841)
        cp (hl)
        jr nz,.background_full_high
        ld a,64
        ld (0xc302),a
        ld (0xc306),a
        ld a,148
        ld (0xc30a),a
        jr .background_band_ready
.background_full_high:
        dec hl
.background_full:
        ld a,(0xc840)
        ld (hl),a
        inc hl
        ld a,(0xc841)
        ld (hl),a
        ld a,1
        ld (de),a
        ld a,32
        ld (0xc302),a
        ld (0xc306),a
        ld a,180
        ld (0xc30a),a
.background_band_ready:
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,(0xc840)
        ld a,h
        add a,5
        cp 9
        jr c,.strip_ready
        add a,3
.strip_ready:
        ld (0xc303),a
        ld a,l
        ld (0xc300),a
        or a
        jr z,.first_ready
        neg
        ld (0xc308),a
        xor a
        ld (0xc309),a
.first_ready:
        ld hl,0xc300
        call command
        ld a,(0xc840)
        or a
        ret z
        ld b,a
        xor a
        ld (0xc300),a
        ld a,(0xc303)
        inc a
        cp 9
        jr nz,.next_strip_ready
        ld a,12                ; skip the HUD and sprite storage in VRAM
.next_strip_ready:
        ld (0xc303),a
        ld a,b
        neg
        ld (0xc304),a
        ld a,b
        ld (0xc308),a
        ld hl,0xc300
        jp command

'''.replace('MISSION_CAMERA_MAX',str(camera_max))
source=source.replace('controls:\n',scroll+'controls:\n',1)
source=source.replace('ld de,0xff60           ; observed arcade left increment','ld de,0xff00           ; mission left increment')
source=source.replace('ld de,0x0070           ; observed arcade right increment','ld de,0x0100           ; mission right increment')
source=source.replace('ld de,0x0200           ; airborne horizontal increments in arcade','ld de,0x0100           ; retain the mission walk speed in the air')
source=source.replace('        ld de,0xfe00\n.air_step:', '        ld de,0xff00\n.air_step:')
# The purple carpet spans y=144..183. Put the feet around its middle, as in
# the reference, instead of anchoring them at the near edge of the carpet.
assert source.count('        ld a,90\n')==2
source=source.replace('        ld a,90\n','        ld a,104\n')
source=source.replace('''        ld a,104
        sub b
''','''        call mission_player_ground
        sub b
''',1)
source=source.replace('''        ld a,104
.player_y:''','''        call mission_player_ground
.player_y:''',1)
# Display the arcade's horizontal flying kick briefly during the jump. The
# input edge already uses the shared attack timer and does not stop movement.
needle='''        ld a,128
        ld (0xc300),a
        ld a,(0xc804)
        ld e,a'''
assert source.count(needle)==1
source=source.replace(needle,'''        ld a,(0xc803)
        cp 25
        jr nc,.air_no_kick
        cp 19
        jr c,.air_no_kick
        ld a,192
        jr .air_pose_ready
.air_no_kick:
        ld a,128
.air_pose_ready:
        ld (0xc300),a
        ld a,(0xc804)
        ld e,a''')
# Four consecutive arcade walking captures instead of repeating two frames.
start=source.index('        ld a,(0xfc9e)\n        and 8\n',source.index('draw:'))
end=source.index('.ground_y:',start)
source=source[:start]+'''        ld a,(0xfc9e)
        and 0x18
        rlca
        rlca
        rlca
        ld (0xc300),a
        ld a,(0xc809)
        or a
        ld a,128               ; right-facing walk at VRAM y=2688
        jr z,.mission_walk_row
        ld a,192               ; left-facing walk at VRAM y=2752
.mission_walk_row:
        ld (0xc302),a
        ld a,10
        ld (0xc303),a
'''+source[end:]
# The held and fallen poses share the walking rows but occupy separate tiles.
needle='''.player_result_ready:
        ld a,(0xc802)'''
assert source.count(needle)==1
source=source.replace(needle,'''.player_result_ready:
        ld a,(0xc823)
        or a
        jr nz,.reaction_active
        ld a,(0xc856)
        or a
        jr nz,.reaction_ready
        ld a,192               ; remain lying down after a fatal hit
        jr .reaction_pose
.reaction_active:
        ld a,(0xc981)
        or a
        ld a,128
        jr nz,.reaction_pose
        ld a,(0xc823)
        cp 31
        ld a,128               ; held upright during the first phase
        jr nc,.reaction_pose
        ld a,192               ; lying on the floor during recovery
.reaction_pose:
        ld (0xc300),a
        ld a,(0xc809)
        or a
        ld a,192               ; right-facing row y=960
        jr z,.reaction_right
        xor a                  ; left-facing row y=1024
        ld (0xc302),a
        ld a,4
        ld (0xc303),a
        jr .reaction_row
.reaction_right:
        ld (0xc302),a
        ld a,3
        ld (0xc303),a
.reaction_row:
        call mission_player_ground
        ld (0xc306),a
.reaction_ready:
        ld a,(0xc802)''')
# The arcade carries horizontal speed into the jump: a direction and jump
# pressed simultaneously from rest do not create momentum in our capture.
needle='''controls:
        ld a,(0xc823)'''
assert source.count(needle)==1
source=source.replace(needle,'''controls:
        ld a,(0xc856)
        or a
        ret z
        ld a,(0xc807)
        ld (0xc81b),a
        ld a,(0xc823)''')
needle='''        ld a,(0xc807)
        ld (0xc808),a'''
assert source.count(needle)==1
source=source.replace(needle,'''        ld a,(0xc81b)
        ld (0xc808),a''')
# A first approximation of the confirmed $fc00 initial vertical speed and
# $0030 increment. Collision/landing rules remain to be ported from arcade.
y=0;velocity=-1024;heights=[0]
while True:
    velocity+=48;y+=velocity
    if y>=0:break
    heights.append((-y)//256)
heights=list(reversed(heights));count=len(heights)
source=source.replace('        ld a,32\n        ld (0xc804),a',f'        ld a,{count}\n        ld (0xc804),a')
start=source.index('jump_heights:');end=source.index('regs:',start)
table='jump_heights:\n'+''.join('        db '+','.join(map(str,heights[i:i+16]))+'\n' for i in range(0,count,16))
source=source[:start]+table+source[end:]
enemy=Path('src/mission_enemy.asm').read_text()+'\n'+Path('src/mission_thrower.asm').read_text()+'\n'+Path('src/mission_waves.asm').read_text()+'\n'+Path('src/mission_ground.asm').read_text()+'\n'+Path('src/mission_doorway.asm').read_text()+'\n'+Path('src/mission_crates.asm').read_text()+'\n'+Path('src/mission_hang.asm').read_text()+'\n'+Path('src/mission_late.asm').read_text()+'\n'+Path('src/mission_fire_barrier.asm').read_text()+'\n'+Path('src/mission_knife_pair.asm').read_text()+'\n'+Path('src/mission_later_encounters.asm').read_text()+'\n'+Path('src/mission_projectiles.asm').read_text()
enemy=enemy.replace('ld de,321\n','ld de,527\n').replace('ld de,505\n','ld de,711\n')
enemy=enemy.replace('dw 521,457,393,329,265,201,137,73','dw 727,663,599,535,471,407,343,279')
(p/'damage-colour.txt').write_text(str(colour)+'\n')
source=source.replace('copy_command:\n',enemy+'\ncopy_command:\n',1)
# The command template is always 21 bytes. Unrolling avoids the repeated
# LDIR branch overhead on every background, actor and HUD copy.
source=source.replace('''copy_command:
        ld de,0xc300
        ld bc,21
        ldir
        ret''', '''copy_command:
        ld de,0xc300
        ld bc,21
'''+('        ldi\n'*21)+'''        ret''',1)
# Circular B1 pages: restore old dirty regions and only stream exposed columns.
source=source.replace('init:\n', 'init:\n        xor a\n        ld (0xcf00),a\n        ld (0xcf02),a\n',1)
source=source.replace('        call mission_init_top\nloop:', '        call mission_init_top\n        call mission_ring_init\nloop:',1)
source=source.replace('        call mission_background\n', '        call mission_ring_background\n',1)
a=source.index('mission_background:\n');b=source.index('controls:\n',a)
source=source[:a]+source[b:]
source=source.replace('command:\n.wait:', 'raw_command:\n.wait:',1)
# Fixed 21-byte V9990 command packets: unroll OTIR to save its loop overhead.
source=source.replace('        ld bc,21*256+0x63\n        otir', '        ld bc,21*256+0x63\n'+'        outi\n'*21)
source=source.replace('copy_command:\n',Path('src/mission_ring.asm').read_text()+'\ncopy_command:\n',1)
# R19 fine (0..7), R20 coarse (8-pixel units), latched during VBlank.
source=source.replace('        ld a,18\n        out (0x64),a\n        ld a,(0xc802)', '        ld a,19\n        out (0x64),a\n        ld a,(0xc840)\n        and 7\n        out (0x63),a\n        ld a,(0xc840)\n        srl a\n        srl a\n        srl a\n        out (0x63),a\n        ld a,18\n        out (0x64),a\n        ld a,(0xc802)',1)
# R17 is changed only when crossing a world strip, avoiding needless writes.
source=source.replace('        ld a,19\n        out (0x64),a', '''        ld a,(0xcf03)
        ld b,a
        ld a,(0xc841)
        cp b
        jr z,.scroll_y_ready
        ld (0xcf03),a
        ld b,a
        ld a,17
        out (0x64),a
        ld a,b
        out (0x63),a
.scroll_y_ready:
        ld a,19
        out (0x64),a''',1)
source=source.replace('        jr loop\n','        jp loop\n',1)
# The mission runs with interrupts disabled: the BIOS interrupt (keyboard
# scan, timers) took frame time it does not need (the controls are read
# directly). After each drawn frame mission_frame_tick advances JIFFY and
# plays five music ticks every six V9990 frames (50 Hz), src/psg_calls.asm.
needle='        call draw\n.wait_end:\n'
assert source.count(needle)==1
source=source.replace(needle,'        call draw\n        call mission_frame_tick\n.wait_end:\n',1)
needle='''        xor 1
        ld (0xc802),a
        ei
        ld a,8
        out (0x64),a'''
assert source.count(needle)==1,source.count(needle)
source=source.replace(needle,needle.replace('        ei\n',''),1)
# The waits count their turns: the frame's spare time for the Z80, also
# while the V9990 ends its last command (mission_frame_tick).
needle='''        call mission_frame_tick
.wait_end:
        di                      ; no interrupt between the blank and the page (music)
        in a,(0x65)
        bit 6,a
        jr nz,.wait_end
.wait_last_command:
        in a,(0x65)
        rrca
        jr c,.wait_last_command
.wait_start:
        in a,(0x65)
        bit 6,a
        jr z,.wait_start
'''
assert source.count(needle)==1,source.count(needle)
source=source.replace(needle,'''        call mission_frame_tick
        ld hl,0
.wait_end:
        di                      ; no interrupt between the blank and the page (music)
        inc hl
        in a,(0x65)
        bit 6,a
        jr nz,.wait_end
.wait_last_command:
        inc hl
        in a,(0x65)
        rrca
        jr c,.wait_last_command
.wait_start:
        inc hl
        in a,(0x65)
        bit 6,a
        jr z,.wait_start
        ld (MISSION_SPARE),hl
''',1)
source=source.replace('        call mission_ring_background\n','        call mission_ring_background\n        call mission_door_setup\n        call mission_final_draw\n',1)
source=source.replace('        call mission_waves_tick\n','        call mission_waves_tick\n        call mission_boss_tick\n',1)
source=source.replace('        call mission_projectiles_draw\n','        call mission_boss_draw\n        call mission_projectiles_draw\n',1)
source=source.replace('copy_command:\n',Path('src/mission_prelude.asm').read_text()+'\n        include "../../src/psg_calls.asm"\n'+prelude_tables+'\ncopy_command:\n',1)
source=source.replace('copy_command:\n',Path('src/mission_boss.asm').read_text()+'\n'+(p/'boss-poses.asm').read_text()+'\n'+Path('src/mission_chain.asm').read_text()+'\n'+(p/'chain-poses.asm').read_text()+'\n'+Path('src/mission_final.asm').read_text()+'\ncopy_command:\n',1)
import mission_ending_data
# The ending bank: the RANKING and text screens run at page 1
# (src/ranking.asm, also entered after GAME OVER), the ending mansion's
# tables are read at page 2 after them.
source+=(f'\nENDING_BANK equ {ending_bank}\n'+Path('src/ranking.asm').read_text()
         +mission_ending_data.source()+'rank_code_end:\n        assert $ <= 0x6000\n'
         +'        org 0x8000+rank_code_end-0x4000\n'+ending_tables+'        ds 0xc000-$,0xff\n')
(p/'ending-bank.txt').write_text(f'{ending_bank}\n')
if INTEGRATED:
    # The game score goes on from Step 7 (c75c..c75e).
    needle='''        ld (0xc75e),a          ; standalone starts with zero accumulated score
        ld hl,0
        ld (0xc75c),hl
'''
    assert source.count(needle)==1
    source=source.replace(needle,'',1)
    for bank in (1,2):
        needle=f'        ld a,{bank}\n        ld (0x7000),a\n        ld (0xc839),a\n        ld hl,0x8000\n        call upload_rle\n'
        assert source.count(needle)==1,bank
        source=source.replace(needle,needle.replace(f'ld a,{bank}\n',f'ld a,{bank+BANK_BASE}\n'))
    # Lost: GAME OVER and the title through pen_try (src/demo_b1.asm).
    needle='mission_game_over_input:\n'
    assert source.count(needle)==1
    source=source.replace(needle,needle+'        xor a\n        ld b,8\n        call 0xf210\n        ret c\n',1)
    (p/'integrated.asm').write_text(source)
else:
    (p/'visual.asm').write_text(source)
