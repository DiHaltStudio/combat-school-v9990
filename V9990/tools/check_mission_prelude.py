"""Screens before the mission (tools/test_mission_prelude.tcl) against the
arcade capture: each screenshot is compared with the arcade frame shown at
the same point, both reduced to the screen's palette."""
import glob, json, sys
from pathlib import Path
import numpy as np
from PIL import Image
p=Path('build/mission/prelude-test')
d=json.load(open('assets/mission/prelude.json'))
fs=sorted(glob.glob('build/mission/prelude-mame/combatsc/*.png'))
first={'attention':3669,'mansion':4247}
worst=0
for name,screen in (('typing','attention'),('soldiers','attention'),('mansion-a','mansion'),('mansion-b','mansion'),('mansion-c','mansion')):
    left=int((p/f'{name}.txt').read_text())
    f=d[screen]['frames']-left              # frame shown: drawn when left was this value
    P=np.array(d[screen]['palette'],float)
    rom=np.asarray(Image.open(p/f'{name}.png').convert('RGB')).astype(float)[13:225,31:287]   # openMSX raw screenshot: 320x240 with borders
    best=None
    for g in (f-1,f,f+1):                    # one frame of latency at most
        ref=np.asarray(Image.open(fs[first[screen]+g-3600]).convert('RGB')).astype(float)[6:218]
        q=P[((ref.reshape(-1,1,3)-P[None])**2).sum(2).argmin(1)].reshape(ref.shape)
        q=(q.astype(int)>>3<<3)
        r=(rom.astype(int)>>3<<3)
        diff=(np.abs(r-q).sum(2)>24).mean()*100
        best=diff if best is None else min(best,diff)
    print(f'{name}: frame {f}, {best:.2f}% pixels differ')
    worst=max(worst,best)
assert worst<2.0,worst   # colour cycle tones at 5 bits per component
print('OK: both screens match the arcade frames within 2%')
