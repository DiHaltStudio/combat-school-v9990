#!/usr/bin/env python3
"""Recreate the four walking poses from the supplied MAME recording.

Requires ffmpeg, numpy, scipy and Pillow. The recording is not needed to build
or run the game; the cleaned PNGs are already present in assets/step4.
"""
import argparse
import subprocess
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import label

parser=argparse.ArgumentParser()
parser.add_argument('video')
parser.add_argument('output', type=Path)
args=parser.parse_args()
raw=subprocess.check_output(['ffmpeg','-v','error','-ss','8.5','-t','3','-i',args.video,
 '-vf','fps=8,crop=1290:950:94:120,scale=256:212',
 '-f','rawvideo','-pix_fmt','rgb24','-'])
frames=np.frombuffer(raw,np.uint8).reshape(-1,212,256,3)
background=np.median(frames,axis=0).astype(np.int16)
args.output.mkdir(parents=True,exist_ok=True)
for index,name in ((2,'right-stride'),(6,'right-close'),(20,'left-stride'),(22,'left-close')):
 frame=frames[index];r,g,b=(frame[:,:,k].astype(int) for k in range(3))
 shirt=(r>130)&(r>g*1.25)&(g>b*1.2);shirt[:145]=False;shirt[183:]=False
 labels,n=label(shirt);sizes=np.bincount(labels.ravel());sizes[0]=0
 if not n or sizes.max()<3:raise ValueError('Player shirt not found')
 ys,xs=np.where(labels==sizes.argmax());left=max(0,min(228,round(xs.mean())-14));top=143
 foreground=np.max(np.abs(frame.astype(np.int16)-background),axis=2)>24
 foreground[:top]=False;foreground[199:]=False;foreground[:,:left]=False;foreground[:,left+28:]=False
 components,n=label(foreground,structure=np.ones((3,3)));ids=np.unique(components[ys,xs]);ids=ids[ids!=0]
 foreground=np.isin(components,ids)
 rgba=np.dstack((frame[top:top+52,left:left+28],foreground[top:top+52,left:left+28].astype(np.uint8)*255))
 Image.fromarray(rgba).resize((28,44),Image.Resampling.LANCZOS).save(args.output/(name+'.png'))
