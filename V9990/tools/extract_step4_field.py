#!/usr/bin/env python3
"""Prepare a clean Step 4 field from the user's MAME no-shots recording.

Requires ffmpeg, numpy and Pillow. The generated asset is checked in, so the
video and this optional tool are not needed to compile the ROM.
"""
import argparse
import subprocess
import numpy as np
from PIL import Image

p=argparse.ArgumentParser()
p.add_argument('video')
p.add_argument('output')
a=p.parse_args()
raw=subprocess.check_output(['ffmpeg','-v','error','-t','35','-i',a.video,'-vf',
 'fps=2,crop=1350:1000:52:0,scale=256:212','-f','rawvideo','-pix_fmt','rgb24','-'])
frames=np.frombuffer(raw,np.uint8).reshape(-1,212,256,3)
field=np.median(frames,axis=0).astype(np.uint8)
# Remove the fixed arcade clock; continue the sky and mountain from nearby.
field[0:27,48:104]=field[0:27,111:167]
# Remove the stationary player using adjacent ground and sandbags.
field[143:180,43:75]=field[143:180,79:111]
# Reconstruct textured ground behind both scoreboards and the player. The
# central strip is clear of arcade overlays, so it can be repeated here.
ground=field[180:190,110:138].copy()
for y in range(180,212):
 for x in range(256):
  field[y,x]=ground[(y-180)%10,x%28]
Image.fromarray(field,'RGB').save(a.output)
