#!/usr/bin/env python3
"""Exploratory stitching of arcade screenshots, excluding HUD and actors."""
from pathlib import Path
import numpy as np
from PIL import Image
p=Path('build/mame-course/combatsc'); files=sorted(p.glob('*.png'))
if len(files)<2: raise SystemExit('No course screenshots; run tools/mame_course_capture.lua first')
images=[np.asarray(Image.open(f).convert('RGB')) for f in files]
positions=[0]; estimates=[]
for prev,cur in zip(images,images[1:]):
 candidates=[]
 for dx in range(0,49):
  a=prev[20:44, 8+dx:248]; b=cur[20:44,8:248-dx]
  score=np.mean(np.any(a!=b,axis=2))
  candidates.append((score,dx))
 score,dx=min(candidates);positions.append(positions[-1]+dx);estimates.append((dx,score))
print('screens',len(files),'distance',positions[-1],'max mismatch',round(max(s for _,s in estimates),3))
print('shifts',positions)
# The clean mountain region can be stitched reliably, while lane obstacles and characters
# need a separate reconstruction. Preserve the source images for that later work.
w=positions[-1]+256; canvas=np.zeros((224,w,3),dtype=np.uint8); coverage=np.zeros((224,w),dtype=np.uint8)
for pos,im in zip(positions,images):
 # only the top sky/mountain/fence strip; sprites and HUD can overlap it
 region=im[16:55]; existing=coverage[16:55,pos:pos+256]; mask=existing==0
 view=canvas[16:55,pos:pos+256];view[mask]=region[mask];existing[mask]=1
Image.fromarray(canvas).save('build/mame-course/panorama-research.png')
# Median along each panorama column reduces moving characters and temporary effects.
# It cannot distinguish actual scroll from repeated patterns or separate overlapping
# moving sprites; this is a research image, not authoritative game data.
result=np.zeros((96,w,3),dtype=np.uint8)
for x in range(w):
 columns=[im[8:104,x-pos,:] for im,pos in zip(images,positions) if 0<=x-pos<256]
 if columns: result[:,x,:]=np.median(np.stack(columns),axis=0).astype(np.uint8)
Image.fromarray(result).save('build/mame-course/panorama-median.png')
Path('build/mame-course/positions.csv').write_text('frame,image,x,match_error\n'+''.join(f'{1080+i*15},{f.name},{positions[i]},{0 if i==0 else estimates[i-1][1]:.5f}\n' for i,f in enumerate(files)))
