#!/usr/bin/env python3
"""Compress sampled arcade ceremony frames into standalone ROM banks.

The graduation ceremony (tools/extract_step7_ceremony.py) is one tall
scene scrolled by the V9990, three more waving flag pictures and eight cap
pictures, all with one palette (weighted k-means over the scene and the
caps), plus the caps' movement (CEREMONY_CAPS): per track a header
(start frame word, x, y, picture, steps word) and one byte per frame,
picture*32 + (dx+2)*5 + (dy+2); ended by start 0xffff."""
import json
import numpy as np
from pathlib import Path
from PIL import Image,ImageDraw
p=Path('build/step7');p.mkdir(parents=True,exist_ok=True)
assets=Path('assets/step7-ending')
names=('map','formation','ceremony','wave1','wave2','wave3','caps','ranks')
chunks=[]
map_colours=None
# One palette for the ceremony scene, the waving flag and the caps, so the
# V9990 can scroll and switch pictures without changing colours.
def ceremony_palette():
 scene=np.asarray(Image.open(assets/'ceremony.png').convert('RGB')).reshape(-1,3)
 caps=[np.asarray(Image.open(assets/f'cap{j}.png').convert('RGBA')).reshape(-1,4) for j in range(8)]
 capp=np.concatenate([c[c[:,3]>0][:,:3] for c in caps])
 u,c=np.unique(np.concatenate([scene]+[capp]*20).astype(int),axis=0,return_counts=True)
 U=u.astype(float);W=c.astype(float)
 # Black (index 0) and the caps' light brown and dark green are fixed so the caps keep their
 # colours, and the uniforms' two light tones (as in the formation picture
 # shown just before) so they do not turn to the caps' brown; an empty
 # cluster is reseeded at the worst-represented colour.
 fixed=np.array([(0,0,0),(214,165,115),(33,49,33),(214,181,140),(181,148,115)],float)
 k=16-len(fixed)
 rng=np.random.default_rng(1)
 C=U[rng.choice(len(U),k,replace=False,p=W/W.sum())]
 for _ in range(30):
  allc=np.vstack([fixed,C])
  dist=((U[:,None]-allc[None])**2).sum(2)
  lab=dist.argmin(1)
  for j in range(k):
   m=lab==j+len(fixed)
   if m.any():C[j]=(U[m]*W[m,None]).sum(0)/W[m].sum()
   else:C[j]=U[(dist.min(1)*W).argmax()]
 pal=[int(v) for c in np.vstack([fixed,C]) for v in c]
 ref=Image.new('P',(1,1));ref.putpalette(pal+[0]*(768-48))
 return ref
ceremony_ref=ceremony_palette()
def opaque_quantize(rgba,ref):
 """Transparent pixels are index 0; opaque ones never use it."""
 pal=np.array(ref.getpalette()[:48]).reshape(16,3)[1:]
 a=np.asarray(rgba).astype(int)
 idx=((a[:,:,None,:3]-pal[None,None])**2).sum(3).argmin(2)+1
 idx[a[:,:,3]==0]=0
 im=Image.fromarray(idx.astype(np.uint8),'P');im.putpalette(ref.getpalette())
 return im
# YOUR TITLE screen, drawn with the arcade font (assets/mission/ending-font.png)
# instead of the 224-line capture scaled to 212 lines, which lost rows of the
# letters. Cell (x, row) of the arcade's 8x8 grid, rows 0..23 at their own
# 8-line pitch from line 0, as the mission's officer screen
# (tools/mission_ending_data.py): without the arcade's P1 (NICK) and score of rows
# 24..27 (asked by the user) the screen fits in 212 lines unscaled. The 1P
# arrow is drawn by src/step7_visual.asm ending_rank_arrow.
FONT=Image.open('assets/mission/ending-font.png').convert('RGB')
FONT_GLYPHS=json.load(open('assets/mission/ending.json'))['glyphs']
def rank_row_y(row):
 return row*8
def font_text(image,x,y,text,colour):
 for i,ch in enumerate(text):
  if ch==' ':continue
  g=FONT_GLYPHS.index(ch)
  for yy in range(8):
   for xx in range(8):
    if FONT.getpixel((g*8+xx,yy))[0]==239:image.putpixel((x+i*8+xx,y+yy),colour)
RANK_TEXT=((12,0,'YOUR  TITLE',(232,0,104)),(21,2,'CAPTAIN'),(9,3,'ACCOMPLISH'),
 (12,5,'YOUR'),(21,5,'FIRST'),(21,6,'LIEUTENANT'),(11,7,'MISSION'),
 (21,8,'SECOND'),(21,9,'LIEUTENANT'),(7,11,'OVER'),(21,11,'MASTER'),
 (11,12,'260000PTS'),(21,12,'SERGEANT'),(7,14,'OVER'),(21,14,'SERGEANT'),
 (11,15,'240000PTS'),(7,17,'OVER'),(21,17,'CORPORAL'),(11,18,'220000PTS'),
 (7,20,'OVER'),(21,20,'PRIVATE'),(11,21,'200000PTS'),(7,23,'UNDERGRADUATE'),
 (21,23,'ROOKIE'))
def ranks_screen():
 image=Image.new('RGB',(256,212),(0,0,0))
 for x,row,text,*colour in RANK_TEXT:
  font_text(image,x*8,rank_row_y(row),text,colour[0] if colour else (0,200,240))
 return image
for name in names:
 if name=='caps':
  atlas=Image.new('RGBA',(256,16))
  for j in range(8):atlas.paste(Image.open(assets/f'cap{j}.png').convert('RGBA'),(j*16,0))
  image=atlas
 elif name=='ranks':
  image=ranks_screen()
 else:
  image=Image.open(assets/(name+'.png')).convert('RGB')
 if name=='ranks':
  colours=[(0,0,0),(0,200,240),(232,0,104),(255,255,255)]
  pal=[v for c in colours for v in c]+[0]*(768-3*len(colours))
  ref=Image.new('P',(1,1));ref.putpalette(pal)
 elif name in ('ceremony','wave1','wave2','wave3','caps'):
  ref=ceremony_ref
 else:
  q=image.quantize(colors=15,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
  original=q.getpalette()[:45]
  ref=Image.new('P',(1,1));ref.putpalette([0,0,0]+original+[0]*(768-48))
 image=opaque_quantize(image,ref) if name=='caps' else image.quantize(palette=ref,dither=Image.Dither.NONE)
 palette=ref.getpalette()[:48]
 if name=='map':
  # Gold: the CONGRATULATIONS square (always gold; the steps' blink).
  map_colours=(image.getpixel((20,40)),min(range(16),key=lambda i:sum((palette[3*i+j]-255)**2 for j in range(3))))
 pixels=list(image.getdata());raw=bytes(pixels[i]*16+pixels[i+1] for i in range(0,len(pixels),2))
 (p/(name+'-reference.bin')).write_bytes(raw)
 encoded=bytearray();i=0
 while i<len(raw):
  j=i+1
  while j<len(raw) and raw[j]==raw[i] and j-i<255:j+=1
  encoded.extend((j-i,raw[i]));i=j
 encoded.append(0)
 chunk=bytes(v>>3 for v in palette)+encoded
 assert name=='ceremony' or len(chunk)<=16384,(name,len(chunk))
 chunks.append(chunk)
 image.putpalette(palette+[0]*(768-48));image.save(p/(name+'-preview.png'))
# Treat the stripes and logo as a single print. Each pose supplies the
# horizontal and vertical edges of the cloth; (u, v) are fractions of the
# distance between the edges. The upper and lower edges are smoothed over
# neighbouring columns so one pixel of noise cannot make the print jump.
logo = np.asarray(Image.open(assets/'msx-logo.png').convert('1'))
logo_h, logo_w = logo.shape
msx_lines = ['msx_flag_tables: dw msx_flag0,msx_flag1,msx_flag2,msx_flag3']
for frame, name in enumerate(('ceremony', 'wave1', 'wave2', 'wave3')):
 im = np.asarray(Image.open(assets/(name+'.png')).convert('RGB'))
 mask = np.any(im[32:190,32:248] != im[5,100], axis=2)
 bounds = [np.flatnonzero(row) for row in mask]
 columns = [np.flatnonzero(column) for column in mask.T]
 valid = [x for x, ys in enumerate(columns) if len(ys) >= 12]
 edges = []
 for edge in (0, -1):
  edge_rows = np.interp(np.arange(mask.shape[1]), valid, [columns[x][edge] for x in valid])
  edges.append(np.convolve(np.pad(edge_rows, 4, mode='edge'), np.ones(9)/9, mode='valid'))
 top, bottom = edges

 msx_lines.append(f'msx_flag{frame}:')
 for y, xs in enumerate(bounds):
  if len(xs) < 2:
   continue
  left, right = xs[0], xs[-1]
  x = np.arange(left, right+1)
  u = (x-left)/(right-left)
  v = np.clip((y-top[x])/np.maximum(1,bottom[x]-top[x]), 0, 1)
  pens = np.minimum((v*10).astype(int), 9) % 2
  # Same map for the black plaque and white letters as for the stripes.
  inside = (u >= .19) & (u < .81) & (v >= .24) & (v < .58)
  tx = ((u[inside]-.19)*logo_w/.62).astype(int)
  ty = ((v[inside]-.24)*logo_h/.34).astype(int)
  pens[inside] = 2 + logo[ty,tx]
  # Header: row, first x. Each span is length (6 bits) and pen (2 bits).
  # A zero ends the row; 255 in place of the row number ends the pose.
  row = [y+32, left+32]
  start = 0
  while start < len(pens):
   end = start + 1
   while end < len(pens) and end-start < 63 and pens[end] == pens[start]:
    end += 1
   row.append((end-start)*4+int(pens[start]))
   start = end
  row.append(0)
  msx_lines.append('        db '+','.join(map(str,row)))
 msx_lines.append('        db 255')
(p/'msx-flag.inc').write_text('\n'.join(msx_lines)+'\n')
# Pack streams consecutively. A stream may cross a bank boundary, always
# between complete count/value pairs; the decoder switches the mapper there.
out=bytearray();locations=[]
for chunk in chunks:
 if len(out)&1: out.append(255)
 remaining=16384-len(out)%16384
 if remaining<48: out.extend(bytes([255])*remaining)
 locations.append((4+len(out)//16384,len(out)%16384))
 out.extend(chunk)
# Cap movement: read in place by the ceremony loop, so it stays in one bank.
d=json.load(open(assets/'caps.json'))
first=d['first_cap']-d['scroll_start']
data=bytearray()
for start,x,y,j,steps in sorted(d['tracks']):
 data+=bytes([start&255,start>>8,x,y,j,len(steps)&255,len(steps)>>8])
 for sj,dx,dy in steps:
  assert -2<=dx<=2 and -2<=dy<=2
  data.append(sj*32+(dx+2)*5+(dy+2))
data+=bytes([255,255])
if len(out)%16384+len(data)>16384:out.extend(bytes([255])*((-len(out))%16384))
caps_location=(4+len(out)//16384,len(out)%16384)
out.extend(data)
out.extend(bytes([255])*((-len(out))%16384))
banks=len(out)//16384
(p/'ending.bin').write_bytes(out)
lines=[f'ENDING_MAP_GOLD equ {map_colours[0]}',f'ENDING_MAP_WHITE equ {map_colours[1]}','; Generated mapper bank and offset for each ending screen.','ending_frames:']
for name,(bank,offset),chunk in zip(names,locations,chunks):
 lines.append(f'        db {bank} ; {name}, {len(chunk)} bytes')
 lines.append(f'        dw 0x{0x8000+offset:04x}')
lines.append(f'ENDING_BANKS equ {banks}')
lines.append(f'ATLAS2_BANK equ {4+banks}          ; atlas2-rle-bank.bin follows ending.bin')
lines.append(f'CEREMONY_CAPS_BANK equ {caps_location[0]}')
lines.append(f'CEREMONY_CAPS_ADDR equ 0x{0x8000+caps_location[1]:04x}')
lines.append('ceremony_cap_size:')
for j in range(8):
 w,h=Image.open(assets/f'cap{j}.png').size
 lines.append(f'        db {w},{h}')
(p/'ending.inc').write_text('\n'.join(lines)+'\n')
(p/'ending-layout.txt').write_text(f'{banks} banks, {sum(map(len,chunks))} bytes compressed, caps {len(data)} bytes\n'+''.join(f'{n}: {len(c)} bytes, bank {b}, offset {o}\n' for n,c,(b,o) in zip(names,chunks,locations)))
# The 1P arrow (src/step7_visual.asm ending_rank_arrow): "1P>" in the arcade
# font, white (index 3 of the ranks palette), 24x8 = 12 bytes per row.
arrow=Image.new('RGB',(24,8),(0,0,0))
font_text(arrow,0,0,'1P>',(255,255,255))
values=[3 if v!=(0,0,0) else 0 for v in arrow.getdata()]
(p/'rank-arrow.bin').write_bytes(bytes(values[i]*16+values[i+1] for i in range(0,len(values),2)))
# Arrow rows, as the screen: OVER rows 23 (ROOKIE) 20 17 14 11.
(p/'rank-rows.inc').write_text('ending_rank_rows: db '+','.join(str(rank_row_y(r)) for r in (23,20,17,14,11))+'\n')
