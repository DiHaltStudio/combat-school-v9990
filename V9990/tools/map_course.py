#!/usr/bin/env python3
"""Build an experimental continuous course from reconstructed MAME tile planes."""
import csv
from pathlib import Path
import numpy as np
from PIL import Image
p=Path('build/course-analysis')
rows=list(csv.DictReader((p/'layer_matches.csv').open()))
if len(rows)<100: raise SystemExit('run COURSE_STRIDE=1 python3 tools/analyze_course_layers.py first')
world=0;prev=int(rows[0]['background_shift']);items=[]
for r in rows:
 shift=int(r['background_shift']);delta=(shift-prev)%256
 if delta>60: raise ValueError(f"ambiguous shift at frame {r['frame']}: {delta}")
 world+=delta;prev=shift
 im=np.asarray(Image.open(p/f"frame-{r['frame']}.png").convert('RGB'))
 items.append((world,im,r))
width=world+256
if width < 2744: raise ValueError(f'course reconstruction is too short: {width} pixels')
out=np.zeros((112,width,3),dtype=np.uint8);coverage=np.zeros(width,dtype=np.uint16)
for x in range(width):
 cols=[im[:,x-pos,:] for pos,im,_ in items if 8<=x-pos<248]
 if cols:
  out[:,x,:]=np.median(np.stack(cols),axis=0).astype(np.uint8)
  coverage[x]=len(cols)
Image.fromarray(out).save(p/'course-reconstruction.png')
with (p/'course_positions.csv').open('w',newline='') as f:
 w=csv.writer(f);w.writerow(['frame','world_offset_estimate','bg_shift','bg_mismatch','fg_shift','fg_mismatch','delta'])
 previous=0
 for pos,_,r in items:
  w.writerow([r['frame'],pos,r['background_shift'],r['background_mismatch'],r['foreground_shift'],r['foreground_mismatch'],pos-previous]);previous=pos
print(f'{len(items)} frames, inferred travel {world} pixels, panorama width {width}; uncovered columns {int(np.count_nonzero(coverage==0))}')
