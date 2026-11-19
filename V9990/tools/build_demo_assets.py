#!/usr/bin/env python3
from PIL import Image
import numpy as np
from pathlib import Path
p=Path('build/demo');p.mkdir(parents=True,exist_ok=True)
bg=Image.open('build/background/plane1.png').convert('RGB').crop((0,0,256,212))
# course-finished.png adds the bars' front posts and the goal scenery.
course=Image.open('build/course-analysis/course-finished.png').convert('RGB').crop((8,0,2752,112))
assert course.size==(2744,112)
# The reconstruction leaves the start line 69 pixels too far back: at the
# start the arcade shows it ahead of the runners, from screen x 100 (video
# capture), whereas here it was at x 31, behind the player. Swap each line
# pixel with the ground 69 pixels ahead. The finish line already matches.
start_line=[(x,y) for y in range(course.height) for x in range(200) if min(course.getpixel((x,y)))>200]
for x,y in start_line:
 ground=course.getpixel((x+69,y)); course.putpixel((x+69,y),course.getpixel((x,y))); course.putpixel((x,y),ground)
frames=[]
for path in [*(f"build/runner-run/{frame}.png" for frame in (1102,1108,1116,1128)), "build/runner-jump/1102.png", "build/runner-bars/1380.png", "build/runner-bars/1410.png", "build/runner-bars/1605.png", "build/runner-bars/1620.png", "build/runner-vault/1714.png", "build/runner-vault/1736.png", "build/runner-vault/1742.png", "build/runner-vault/1748.png", "build/runner-vault/1754.png"]:
 source=Image.open(path).convert("RGBA")
 bbox=source.getbbox()
 if not bbox: raise ValueError(f'empty frame {path}')
 cropped=source.crop(bbox)
 if 'runner-vault' in path:
  runner=Image.new('RGBA',(32,48))
  # Keep the original width and align the lowest visible pixel to the feet/hands anchor.
  dy=48-bbox[3]
  runner.paste(source.crop((0,0,32,48)),(0,dy))
 elif path.endswith(('1380.png','1410.png','1605.png','1620.png')):
  runner=Image.new('RGBA',(48,48))
  runner.paste(cropped,((48-cropped.width)//2,48-cropped.height),cropped)
 elif 'runner-bars' in path:
  runner=source.crop((0,0,32,56))
 elif 'runner-jump' in path:
  # Keep native pixels: a 41-pixel-wide jump needs a 48-pixel slot.
  runner=Image.new('RGBA',(48,48))
  runner.paste(cropped,((48-cropped.width)//2,48-cropped.height),cropped)
 else:
  runner=source.crop((0,0,32,48))
 frames.append(runner)
# Native CPU sprites use the arcade's own palette: exposed skin stays skin-coloured.
cpu_frames=[]
for frame in (1155,1215,1080,1095,1110,2280):
 source=Image.open(f'build/cpu-reference/{frame}.png').convert('RGBA')
 if frame==1110:
  bbox=source.getbbox(); cropped=source.crop(bbox)
  canvas=Image.new('RGBA',(48,48))
  canvas.paste(cropped,((48-cropped.width)//2,48-cropped.height),cropped)
 else:
  canvas=source.crop((0,0,32,48))
 cpu_frames.append(canvas)   # arcade colours, as the arcade CPU
instructors=[Image.open(f'build/instructor/{frame}.png').convert('RGBA') for frame in (804,876,888,2280)]
# Poses 4 and 5: pointing the baton at the runner and raising it, at the goal.
instructors+=[Image.open(f'build/goal/instructor-{name}.png').convert('RGBA') for name in ('point','baton')]
# Reservar índice cero para transparencia y compartir 15 colores.
sample=Image.new('RGB',(2744,212+64*(len(frames)+len(cpu_frames)+len(instructors))+112))
sample.paste(bg,(0,0))
sample.paste(course,(0,212+64*(len(frames)+len(cpu_frames)+len(instructors))))
for i,runner in enumerate(frames+cpu_frames+instructors): sample.paste(runner,(64,212+i*64),runner)
# Fixed palette with exact arcade colours. A median cut over the whole course
# merged the runners' three greens into one grey-green and greyed the skin, so
# the colours the player and the CPU need get their own pens, and the course
# shares them. Pen 0 is black (transparent in sprites, black in the course).
pal=[0,0,0,
     0,165,231,    # 1 sky
     165,140,123,  # 2 ground
     90,90,90,     # 3 grey
     123,123,123,  # 4 light grey
     123,123,165,  # 5 mountains
     33,66,33,     # 6 dark green: trousers, instructor
     74,107,0,     # 7 green: trousers
     206,115,107,  # 8 skin
     181,165,145,  # 9 pale beige: wall faces, light skin
     66,66,41,     # 10 olive; also the course's dark grey
     220,110,10,   # 11 player shirt orange
     0,90,57,      # 12 trees
     248,248,240,  # 13 white (UI, start and finish lines)
     132,181,140,  # 14 light green: CPU shirt, POWER gauge
     240,0,0]      # 15 red
_pal=np.array(pal,float).reshape(16,3)
def pens(img,first=0):
 """Nearest pen of each pixel (weighted RGB), from `first` upwards."""
 a=np.asarray(img.convert('RGB'),float).reshape(-1,3)
 d=(((a[:,None,:]-_pal[None,first:])**2)*(2,4,3)).sum(-1)
 return [int(v)+first for v in d.argmin(1)]
(p/'palette.bin').write_bytes(bytes(v>>3 for v in pal))
course_pens=pens(course)
pixels=pens(bg)
(p/'image.bin').write_bytes(bytes(pixels[i]*16+pixels[i+1] for i in range(0,len(pixels),2)))
# 256x112 chunks in consecutive 16 KiB ROM banks, each padded to one bank.
# The start and finish lines are the only white pixels of the course. The
# walls' pale faces would fall into the ground colour: give them the pale
# beige (pen 9), and keep their dark edge black.
wall_face={(165,156,140),(181,165,140),(198,189,165),(160,148,132),(165,148,131),(181,172,152)}
for i,rgb in enumerate(course.getdata()):
 if min(rgb)>200: course_pens[i]=13
 elif rgb in wall_face: course_pens[i]=9
 elif rgb==(33,33,33): course_pens[i]=0
course_indexed=Image.new('P',course.size); course_indexed.putpalette(pal); course_indexed.putdata(course_pens)
course_data=bytearray()
for left in range(0,2744,256):
 page=Image.new('P',(256,112),0)
 page.paste(course_indexed.crop((left,0,min(left+256,2744),112)),(0,0))
 data=list(page.getdata())
 packed=bytes(data[i]*16+data[i+1] for i in range(0,len(data),2))
 course_data.extend(packed+bytes([0xff])*(0x4000-len(packed)))
(p/'course.bin').write_bytes(course_data)
course_indexed.save(p/'course-preview.png')
packed=[]
def player_pen(value,rgba):
 r,g,b,alpha=rgba
 if not alpha: return 0
 if r>=180 and 55<=g<=160 and b<=45: return 11
 return value
for runner in frames:
 sprite=pens(runner,1)
 sp=[player_pen(v,rgba) for v,rgba in zip(sprite,runner.getdata())]
 packed.extend(bytes(sp[i]*16+sp[i+1] for i in range(0,len(sp),2)))
# Preserve each captured hanging pose's position relative to the same arcade anchor.
hanging=[]
for frame in (2300,2304,2308,2320,2324,2330):
 source=Image.open(f'build/runner-bars-dense/{frame}.png').convert('RGBA')
 raw=Path(f'build/mame-bars/frame-{frame}/videoram1.bin').read_bytes()[0x1800:]
 xs=[]
 for i in range(64):
  obj=raw[i*5:i*5+5]; x=obj[3]-(256 if obj[4]&1 else 0); y=obj[2]-(256 if obj[2]>=240 else 0)
  if obj[1]>>4==1 and 40<=x<=150 and 25<=y<=140: xs.append(x)
 if not xs: raise ValueError(f'missing hanging sprite {frame}')
 canvas=Image.new('RGBA',(48,56))
 canvas.paste(source,(min(xs)-100,0),source)
 hanging.append(canvas)
(p/'runner.bin').write_bytes(bytes(packed))
hang_data=[]
for sprite_img in hanging:
 indexed_h=pens(sprite_img,1)
 sp=[player_pen(v,rgba) for v,rgba in zip(indexed_h,sprite_img.getdata())]
 hang_data.extend(bytes(sp[i]*16+sp[i+1] for i in range(0,len(sp),2)))
(p/'hang.bin').write_bytes(bytes(hang_data))
cpu_data=[]
for sprite_img in cpu_frames:
 indexed_cpu=pens(sprite_img,1)
 sp=[v if alpha else 0 for v,alpha in zip(indexed_cpu,sprite_img.getchannel('A').getdata())]
 cpu_data.extend(bytes(sp[i]*16+sp[i+1] for i in range(0,len(sp),2)))
(p/'cpu.bin').write_bytes(bytes(cpu_data))
# Two 48x48 seated landing poses, sharing the course palette.
seated_data=[]
for filename,is_player in (('seated-player.png',True),('seated-cpu.png',False)):
 img=Image.open('assets/runner/'+filename).convert('RGBA')
 assert img.size==(48,48)
 idx=pens(img,1)
 sp=[(player_pen(v,rgba) if is_player else v) if rgba[3]>=128 else 0
     for v,rgba in zip(idx,img.getdata())]
 seated_data.extend(bytes(sp[i]*16+sp[i+1] for i in range(0,len(sp),2)))
# Goal poses of the player, 32x64 with feet on the last row, stored after the
# seated poses in the same bank: bent, standing, arm half raised, arm raised.
for name in ('bent','stand','half','raised'):
 img=Image.open(f'build/goal/player-{name}.png').convert('RGBA')
 assert img.size==(32,64)
 idx=pens(img,1)
 sp=[player_pen(v,rgba) for v,rgba in zip(idx,img.getdata())]
 seated_data.extend(bytes(sp[i]*16+sp[i+1] for i in range(0,len(sp),2)))
(p/'seated.bin').write_bytes(bytes(seated_data))
instructor_data=[]
uniform_green=7   # arcade green (74,107,0), as on the runners' trousers
for sprite_img in instructors:
 indexed_i=pens(sprite_img,1)
 # Preserve the instructor's green uniform against the similarly coloured fence.
 # The light green is already reserved for the POWER gauge.
 sp=[]
 for value,rgba in zip(indexed_i,sprite_img.getdata()):
  r,g,b,alpha=rgba
  if not alpha: sp.append(0)
  elif (r,g,b)==(90,123,33): sp.append(uniform_green)
  elif (r,g,b)==(140,148,107): sp.append(14)
  else: sp.append(value)
 instructor_data.extend(bytes(sp[i]*16+sp[i+1] for i in range(0,len(sp),2)))
(p/'instructor.bin').write_bytes(bytes(instructor_data))
preview=Image.new('P',bg.size); preview.putpalette(pal); preview.putdata(pixels); preview.save(p/'preview.png')
frames[0].save(p/'runner.png')
# The first ten cells form the arcade-style clock; the others are result text.
glyphs=('111101101101111','010110010010111','111001111100111',
        '111001111001111','101101111001001','111100111001111',
        '111100111101111','111001001001001','111101111101111',
        '111101111001111',
        '111100100100111','110101110100100','101101101101111',
        '101101010010010','111101101101111','111100110100111',
        '101111111111101','110101101101110')
colors=[tuple(pal[i*3:i*3+3]) for i in range(16)]
white,green,red=13,14,15
shadow=min(range(1,13),key=lambda i:sum(colors[i]))   # dark green
# Rows 0-15: clock digits, letters and POWER. Rows 16-25: the arcade's
# PLAYER 1(NICK) and YOU MADE IT, each copied with a single command; rows
# 32-41: YOU BLEW IT in red (a lost race, as in the arcade) and the red 1P.
ui=Image.new('P',(240,42),0)
from PIL import ImageDraw
draw=ImageDraw.Draw(ui)
segments=('abcdef','bc','abged','abgcd','fgbc','afgcd','afgecd','abc','abcdefg','abfgcd')
for digit,active in enumerate(segments):
 mask=Image.new('1',(8,16)); md=ImageDraw.Draw(mask)
 coords={'a':(1,1,5,2),'b':(5,2,6,6),'c':(5,7,6,11),
         'd':(1,11,5,12),'e':(0,7,1,11),'f':(0,2,1,6),'g':(1,6,5,7)}
 for segment in active: md.rectangle(coords[segment],fill=1)
 ui.paste(shadow,(digit*8+1,1),mask.crop((0,0,7,15)))
 ui.paste(white,(digit*8,0),mask)
for digit,pattern in enumerate(glyphs[10:],10):
 for y in range(5):
  for x in range(3):
   if pattern[y*3+x]=='1':
    draw.rectangle((digit*8+x*2+1,y*2+2,digit*8+x*2+2,y*2+3),fill=white)
# Cells 25-29: M, I, A, T, S (M, A and T spell YOU MADE IT).
for digit,pattern in enumerate(('101111111101101','111010010010111',
                                '010101111101101','111010010010010','011100010001110'),25):
 for y in range(5):
  for x in range(3):
   if pattern[y*3+x]=='1':
    draw.rectangle((digit*8+x*2+1,y*2+2,digit*8+x*2+2,y*2+3),fill=white)
for glyph,points in ((18,((3,4),(3,9))),(19,((3,11),))):
 for x,y in points:
  draw.rectangle((glyph*8+x+1,y+1,glyph*8+x+2,y+2),fill=shadow)
  draw.rectangle((glyph*8+x,y,glyph*8+x+1,y+1),fill=white)
# POWER legend occupies the rightmost five cells of the first eight rows.
power=('11110/10001/10001/11110/10000/10000',
       '01110/10001/10001/10001/10001/01110',
       '10001/10001/10101/10101/11011/10001',
       '11111/10000/11110/10000/10000/11111',
       '11110/10001/11110/10100/10010/10001')
for offset,colour in ((1,shadow),(0,red)):
 for index,pattern in enumerate(power):
  for y,line in enumerate(pattern.split('/')):
   for x,bit in enumerate(line):
    if bit=='1':draw.point((160+index*8+x+offset,y+offset),fill=colour)
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from arcade_font import draw_text
draw_text(draw,0,16,'PLAYER 1(NICK)',white,scale=2,shadow=shadow)
draw_text(draw,112,16,'YOU MADE IT',white,scale=2,shadow=shadow)
draw_text(draw,0,32,'YOU BLEW IT',red,scale=2,shadow=shadow)
# Red 1P of the single game score (src/demo_b1.asm score_ui), x 96-111.
draw_text(draw,96,32,'1P',red,scale=2,shadow=shadow)
pixels=list(ui.getdata())
(p/'ui.bin').write_bytes(bytes(pixels[i]*16+pixels[i+1] for i in range(0,len(pixels),2)))
(p/'ui.inc').write_text(f'UI_RED equ {red}\nUI_WHITE equ {white}\nUI_GREEN equ {green}\nUI_SHADOW equ {shadow}\n')
cpu_hang=[]
for frame in (1845,1770,1815,1785,1830,1755):
 source=Image.open(f'build/cpu-reference/{frame}.png').convert('RGBA')
 raw=Path(f'build/mame-course-state/frame-{frame}/videoram1.bin').read_bytes()[0x1800:]
 xs=[]
 for i in range(64):
  obj=raw[i*5:i*5+5]; x=obj[3]-(256 if obj[4]&1 else 0); y=obj[2]-(256 if obj[2]>=240 else 0)
  if obj[1]==0 and 40<=x<=150 and 140<=y<=220: xs.append(x)
 if not xs: raise ValueError(f'missing CPU hanging sprite {frame}')
 canvas=Image.new('RGBA',(48,56))
 canvas.paste(source,(min(xs)-90,0),source)
 indexed_h=pens(canvas,1)
 sp=[v if alpha else 0 for v,alpha in zip(indexed_h,canvas.getchannel('A').getdata())]
 cpu_hang.extend(bytes(sp[i]*16+sp[i+1] for i in range(0,len(sp),2)))
(p/'cpu-hang.bin').write_bytes(bytes(cpu_hang))
