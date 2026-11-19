#!/usr/bin/env python3
"""Match reconstructed arcade tilemap planes against course screenshots.
The register/bank and scrolling assumptions are experimental; sprites are excluded.
"""
import csv
import os
from pathlib import Path
import subprocess
import sys
import numpy as np
from PIL import Image
root=Path('build/mame-course-state')
out=Path('build/course-analysis');out.mkdir(parents=True,exist_ok=True)
files=sorted((root/'combatsc').glob('*.png'))
if not files: raise SystemExit('capture MAME course state first')
def captured_scroll(capture, circuit):
 # The renderer already applies the live K007121 scroll. Image matching
 # measures only its residual correction; restore the hardware displacement
 # when recording the world position used by map_course.py.
 regs=dict(line.split('=',1) for line in (capture/'registers.txt').read_text().splitlines())
 ctrl=[int(value,16) for value in regs[f'ctrl{circuit}'].split()]
 if ctrl[1]&2:
  return (capture/f'scrollram{circuit}.bin').read_bytes()[5]
 return ctrl[0]+((ctrl[1]&1)<<8)

rows=[]
for i in range(0,len(files),int(os.getenv('COURSE_STRIDE','3'))):
 frame=1080+i*15;cap=root/f'frame-{frame:04d}'
 subprocess.run([sys.executable,'tools/render_background.py',str(cap),'--vreg','0x33','--out',str(out/'planes')],check=True,stdout=subprocess.DEVNULL)
 bg=np.asarray(Image.open(out/'planes/plane1.png').convert('RGB'))
 fg=np.asarray(Image.open(out/'planes/plane0.png').convert('RGBA'))
 snap=np.asarray(Image.open(files[i]).convert('RGB'))
 scores=[]
 for shift in range(256):
  candidate=np.roll(bg,-shift,axis=1)
  scores.append(np.mean(np.any(candidate[25:100,8:248]!=snap[25:100,8:248],axis=2)))
 bgshift=int(np.argmin(scores));bgerr=scores[bgshift]
 scores=[]
 for shift in range(256):
  candidate=np.roll(fg,-shift,axis=1); region=candidate[25:100,8:248];mask=region[:,:,3]!=0
  if mask.sum()<80: scores.append(1.0);continue
  scores.append(np.mean(np.any(region[:,:,:3]!=snap[25:100,8:248],axis=2)[mask]))
 fgshift=int(np.argmin(scores));fgerr=scores[fgshift]
 bg=np.roll(bg,-bgshift,axis=1);fg=np.roll(fg,-fgshift,axis=1)
 mask=fg[:,:,3]!=0;composed=bg.copy();composed[mask]=fg[:,:,:3][mask]
 Image.fromarray(composed[:112]).save(out/f'frame-{frame}.png')
 rows.append((frame,files[i].name,(bgshift+captured_scroll(cap,1))%256,round(bgerr,4),(fgshift+captured_scroll(cap,0))%256,round(fgerr,4)))
with (out/'layer_matches.csv').open('w',newline='') as f:
 w=csv.writer(f);w.writerow(['frame','screenshot','background_shift','background_mismatch','foreground_shift','foreground_mismatch']);w.writerows(rows)
print('Analyzed',len(rows),'frames; exact foreground matches:',sum(r[5]==0 for r in rows))
print('CSV:',out/'layer_matches.csv')
