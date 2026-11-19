#!/usr/bin/env python3
"""Verify background, sprite composition and palette in a captured openMSX state."""
import sys
from pathlib import Path
from PIL import Image
p=Path('build/demo'); dump=Path(sys.argv[1]) if len(sys.argv)>1 else p/'dump'
phys=(dump/'v9_vram.bin').read_bytes(); regs=(dump/'v9_regs.bin').read_bytes(); palette=(dump/'v9_pal.bin').read_bytes(); expected=(p/'image.bin').read_bytes(); sprite=(p/'runner.bin').read_bytes(); raw_ram=(dump/'ram.bin').read_bytes(); ram=bytearray(raw_ram); published=0xc100+0x100*(regs[18]&1); ram[0xc000:0xc100]=raw_ram[published:published+0x100]; x=ram[0xc000]; source_x=ram[0xc030]; source_y=ram[0xc032]+ram[0xc033]*256
goal_pose=source_y==2816 and source_x in (96,128,160,192)
if goal_pose:
 # 32x64 goal poses stored after the two seated poses.
 frame="goal"; width=32; height=64; draw_x=x
 k=(source_x-96)//32
 sprite=(p/'seated.bin').read_bytes()[2304+k*1024:2304+(k+1)*1024]
elif source_y==2816:
 assert source_x==0, 'invalid seated player frame'
 frame="seated"; width=48; height=48; draw_x=x-8
 sprite=(p/'seated.bin').read_bytes()[:1152]
elif source_y in (2304,2368):
 assert (source_y==2304 and source_x in (0,48,96,144,192)) or (source_y==2368 and source_x==0), 'invalid hanging frame'
 frame=(source_x//48 if source_y==2304 else 5); width=48; height=56
 sprite=(p/'hang.bin').read_bytes()[frame*1344:(frame+1)*1344]; draw_x=x-8
elif source_y==664:
 assert source_x in (0,32,64,96,128), 'invalid climbing frame'
 frame=11+source_x//32; width=32; height=48
 sprite=sprite[8832+(frame-11)*768:8832+(frame-10)*768]
 edge=ram[0xc083]+256*ram[0xc084]-53-(ram[0xc006]+256*ram[0xc00c])
 draw_x=max(x-8,edge-{0:30,32:25,64:17,96:4}[source_x]) if source_x in (0,32,64,96) else max(x,edge-10) if source_x==128 else x
elif source_y==600:
 assert source_x in (0,48,96,144), 'invalid fall frame'
 frame=7+source_x//48; width=48; height=48
 sprite=sprite[4224+(frame-7)*1152:4224+(frame-6)*1152]; draw_x=x-8
else:
 assert source_y==512 and source_x in (0,32,64,96,128), 'invalid sprite frame'
 frame={0:0,32:1,64:2,96:3,128:4,176:5,208:6}[source_x]; width=48 if frame==4 else 32; height=56 if frame>=5 else 48
 sprite=sprite[4224+(frame-5)*896:4224+(frame-4)*896] if frame>=5 else sprite[3072:4224] if frame==4 else sprite[frame*768:(frame+1)*768]; draw_x=x-8 if frame==4 else x
logical=bytearray(len(phys));logical[0::2]=phys[:0x40000];logical[1::2]=phys[0x40000:]
display_y=regs[17]+256*(regs[18]&31)
assert display_y in (0,256), f'unexpected display page {display_y}'
assert regs[6]==0x81 and regs[8]==0xc2, 'unexpected mode/display registers'
assert b''.join(palette[i*4:i*4+3] for i in range(16))==(p/'palette.bin').read_bytes(), 'palette mismatch'
model=bytearray(expected)
scroll=ram[0xc006]+256*ram[0xc00c]
assert scroll % 2 == 0 and scroll <= 2488
course=(p/'course.bin').read_bytes()
for page in range(11):
 base=0x18000+page*0x4000
 assert logical[base:base+14336] == course[page*0x4000:page*0x4000+14336], f'course page {page} mismatch'
for row in range(112):
 line=bytearray()
 for page in range(11):
  pos=page*0x4000+row*128
  line.extend(course[pos:pos+128])
 start=row*128
 model[start:start+128]=line[scroll//2:scroll//2+128]
cpu_scroll=ram[0xc090]+256*ram[0xc091]
cpu_x=ram[0xc092]
for row in range(100):
 line=bytearray()
 for page in range(11):
  pos=page*0x4000+row*128
  line.extend(course[pos:pos+128])
 start=(row+112)*128
 model[start:start+128]=line[cpu_scroll//2:cpu_scroll//2+128]
y=ram[0xc005]-(16 if goal_pose else 0)
if source_y==664 and source_x in (0,32,64,96):
 y=ram[0xc085]+{0:39,32:13,64:0,96:-5}[source_x]
for row in range(height):
 for col in range(width):
  b=sprite[row*(width//2)+col//2]; pen=b>>4 if col%2==0 else b&15
  if pen:
   index=(y+row)*128+(draw_x+col)//2
   if (draw_x+col)%2: model[index]=(model[index]&0xf0)|pen
   else: model[index]=(model[index]&0x0f)|(pen<<4)
cpu_src=ram[0xc0a0]
cpu_y=ram[0xc0a6]
cpu_source_y=ram[0xc0a2]+256*ram[0xc0a3]
if cpu_source_y==2816:
 assert cpu_src==48, 'invalid seated CPU frame'
 cpu_width=48; cpu_height=48; cpu_draw_x=cpu_x-8
 cpu_sprite=(p/'seated.bin').read_bytes()[1152:2304]
elif cpu_source_y in (2560,2624):
 cpu_frame=cpu_src//48 if cpu_source_y==2560 else 5
 cpu_width=48; cpu_height=56; cpu_draw_x=cpu_x-8
 cpu_raw=(p/'cpu-hang.bin').read_bytes()
 cpu_sprite=cpu_raw[cpu_frame*1344:(cpu_frame+1)*1344]
else:
 assert cpu_source_y==2432
 cpu_width=48 if cpu_src==128 else 32
 cpu_height=48
 cpu_draw_x=cpu_x-8 if cpu_src==128 else cpu_x
 cpu_raw=(p/'cpu.bin').read_bytes()
 cpu_sprite=cpu_raw[3072:4224] if cpu_src==128 else cpu_raw[4224:4992] if cpu_src==176 else cpu_raw[(cpu_src//32)*768:(cpu_src//32+1)*768]
for row in range(min(cpu_height,212-cpu_y)):
 for col in range(cpu_width):
  b=cpu_sprite[row*(cpu_width//2)+col//2]; pen=b>>4 if col%2==0 else b&15
  if pen:
   index=(cpu_y+row)*128+(cpu_draw_x+col)//2
   if (cpu_draw_x+col)%2: model[index]=(model[index]&0xf0)|pen
   else: model[index]=(model[index]&0x0f)|(pen<<4)
# Both cameras show each runner at its world position; clip at screen edges.
for raw,w,h,dx,dy in (
    (cpu_sprite,cpu_width,cpu_height,cpu_scroll+cpu_draw_x-scroll,
     cpu_y-(112 if cpu_source_y in (2560,2624) else 104)),
    (sprite,width,height,scroll+draw_x-cpu_scroll,
     y+(112 if source_y in (2304,2368) else 104))):
 for row in range(h):
  if not 0<=dy+row<212: continue
  for col in range(w):
   if not 0<=dx+col<256: continue
   b=raw[row*(w//2)+col//2];pen=b>>4 if col%2==0 else b&15
   if pen:
    index=(dy+row)*128+(dx+col)//2
    if (dx+col)%2: model[index]=(model[index]&0xf0)|pen
    else: model[index]=(model[index]&15)|(pen<<4)
# The instructor is composed over each independent lane near a line.
instructor=(p/'instructor.bin').read_bytes()
pose=ram[0xc0be]
for flag,dx,dy in ((1,ram[0xc0bc],39),(2,ram[0xc0bd],139)):
 if not ram[0xc0bb] & flag: continue
 for row in range(64):
  for col in range(48):
   b=instructor[pose*1536+row*24+col//2]; pen=b>>4 if col%2==0 else b&15
   if pen:
    index=(dy+row)*128+(dx+col)//2
    if (dx+col)%2: model[index]=(model[index]&0xf0)|pen
    else: model[index]=(model[index]&0x0f)|(pen<<4)
# Clock glyphs and energy bars are composed after the actors.
ui=(p/'ui.bin').read_bytes()
seconds=ram[0xc0df]
status=ram[0xc0d9]
# YOU MADE IT whenever the player reaches the goal in time; YOU BLEW IT
# (red, UI rows 32-41) when the time runs out.
result_glyphs=()
digits=[(g,x,0) for g,x in ((seconds//60,184),(18,192),((seconds%60)//10,200),(seconds%10,208),(19,216),(ram[0xc0de],224))]+list(result_glyphs)
for digit,dx,dy in digits:
 for row in range(16):
  for col in range(8):
   b=ui[row*120+digit*4+col//2]; pen=b>>4 if col%2==0 else b&15
   if pen:
    i=(dy+row)*128+(dx+col)//2
    model[i]=((model[i]&15)|(pen<<4)) if col%2==0 else ((model[i]&240)|pen)
# Single game score (src/demo_b1.asm score_ui): red 1P from UI (96,32) at
# (16,3) and the total left-aligned from x 40 in clock cells. C75C..E is
# not part of the published page state, so the shown page may predate the
# last addition (10 per stride, 500 per wall): accept those earlier values.
def score_model(value):
 m=bytearray(model)
 cells=[(int(ch),40+8*k) for k,ch in enumerate(str(value))]
 for digit,dx in cells:
  for row in range(16):
   for col in range(8):
    b=ui[row*120+digit*4+col//2]; pen=b>>4 if col%2==0 else b&15
    if pen:
     i=row*128+(dx+col)//2
     m[i]=((m[i]&15)|(pen<<4)) if col%2==0 else ((m[i]&240)|pen)
 for row in range(10):
  for col in range(16):
   b=ui[(32+row)*120+(96+col)//2]; pen=b>>4 if col%2==0 else b&15
   if pen:
    i=(3+row)*128+(16+col)//2
    m[i]=((m[i]&15)|(pen<<4)) if col%2==0 else ((m[i]&240)|pen)
 return m
score=ram[0xc75c]+256*ram[0xc75d]+65536*ram[0xc75e]
shown=logical[display_y*128:display_y*128+16*128]
for candidate in (score,score-10,score-500,score-510):
 if candidate>=0 and score_model(candidate)[:16*128]==shown: break
else:
 raise AssertionError(f'score {score} not shown')
model=score_model(candidate)
# Arcade upper lane labels: PLAYER 1(NICK) at (17,22), YOU MADE IT at (41,38).
if status in (1,2,3):
 for sx,sy,w,dx,dy in ((0,16,112,17,22),(112,16,88,41,38) if status!=3 else (0,32,88,41,38)):
  for row in range(10):
   for col in range(w):
    b=ui[(sy+row)*120+(sx+col)//2]; pen=b>>4 if (sx+col)%2==0 else b&15
    if pen:
     i=(dy+row)*128+(dx+col)//2
     model[i]=((model[i]&15)|(pen<<4)) if (dx+col)%2==0 else ((model[i]&240)|pen)
constants={line.split()[0]:int(line.split()[-1]) for line in (p/'ui.inc').read_text().splitlines()}
for yy,bar_width in ((114,ram[0xc008]*2),(204,0 if ram[0xc095] else ram[0xc097]//2)):
 for row in range(8):
  for col in range(40):
   b=ui[row*120+80+col//2]; pen=b>>4 if col%2==0 else b&15
   if pen:
    i=(yy+row)*128+(4+col)//2
    model[i]=((model[i]&15)|(pen<<4)) if col%2==0 else ((model[i]&240)|pen)
 for yoff,width,colour in ((1,96,constants['UI_SHADOW']),(0,96,constants['UI_GREEN']),(0,bar_width,constants['UI_RED'])):
  for row in range(6):
   for col in range(width):
    i=(yy+yoff+row)*128+(44+col)//2
    model[i]=((model[i]&15)|(colour<<4)) if col%2==0 else ((model[i]&240)|colour)
actual=logical[display_y*128:display_y*128+len(expected)]
if actual!=model:
 bad=[i for i,(a,b) in enumerate(zip(actual,model)) if a!=b]
 print('differences',len(bad),'bounds',min(i//128 for i in bad),max(i//128 for i in bad),'first',[(i//128,i%128,actual[i],model[i]) for i in bad[:8]])
 raise AssertionError('display does not match composed background and sprite')
im=Image.new('RGB',(256,212));im.putdata([tuple((v<<3)|(v>>2) for v in palette[n*4:n*4+3]) for b in model for n in (b>>4,b&15)]);im.save(p/'verified.png')
print(f'OK: background, 16 colours, composed runner at x={x}, y={y}, scroll={scroll}, CPU={cpu_scroll}, frame={frame}')
