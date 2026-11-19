#!/usr/bin/env python3
"""Estimate a vertical course mosaic from consistently cropped MAME frames.

The output is an analysis aid, not a verified collision map. Input must be
120x173 RGB frames ordered in time. NumPy and Pillow are required.
"""
import argparse
from pathlib import Path
import numpy as np
import warnings
from PIL import Image

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('frames',type=Path)
p.add_argument('output',type=Path)
args=p.parse_args()
paths=sorted(args.frames.glob('*.png'))
if len(paths)<2:
    raise SystemExit('At least two ordered PNG frames are needed')
frames=[np.asarray(Image.open(path).convert('RGB'),dtype=np.int16) for path in paths]
if any(a.shape!=(173,120,3) for a in frames):
    raise SystemExit('Expected 120x173 frames')
offsets=[0]
scores=[]
for previous,current in zip(frames,frames[1:]):
    errors=[]
    for dy in range(66):
        difference=np.abs(current[12+dy:155]-previous[12:155-dy]).mean(axis=2)
        # The actor occupies the middle of its camera; use the two sides.
        comparison=np.concatenate((difference[:,:45],difference[:,85:]),axis=1)
        errors.append(float(np.minimum(comparison,50).mean()))
    shift=int(np.argmin(errors))
    offsets.append(offsets[-1]+shift)
    scores.append(errors[shift])

height=offsets[-1]+173
canvas=np.zeros((height,120,3),dtype=np.uint8)
coverage=np.zeros((height,120),dtype=np.uint8)
# Position n corresponds to the beginning of the extracted sequence; walking
# forward moves the scene down, so image rows are mapped with decreasing world Y.
for world_y in range(-offsets[-1],173):
    candidates=[]
    for image,offset in zip(frames,offsets):
        screen_y=world_y+offset
        if 28<=screen_y<160:
            row=image[screen_y].copy()
            # Exclude the runner in the centre of the screen.
            if 70<=screen_y<140:
                row[42:88]=-1
            candidates.append(row)
    if not candidates:
        continue
    stack=np.array(candidates,dtype=np.float32)
    stack[stack<0]=np.nan
    with warnings.catch_warnings():
        warnings.simplefilter('ignore',RuntimeWarning)
        median=np.nanmedian(stack,axis=0)
    good=np.isfinite(median).all(axis=1)
    canvas[world_y+offsets[-1],good]=median[good].astype(np.uint8)
    coverage[world_y+offsets[-1],good]=1
args.output.mkdir(parents=True,exist_ok=True)
Image.fromarray(canvas).save(args.output/'land-mosaic.png')
Image.fromarray(coverage*255).save(args.output/'land-coverage.png')
(args.output/'offsets.txt').write_text('\n'.join(f'{p.name} {o} {0 if i==0 else scores[i-1]:.2f}' for i,(p,o) in enumerate(zip(paths,offsets)))+'\n')
print(f'{len(paths)} frames, estimated progress {offsets[-1]} pixels, coverage {coverage.mean():.1%}')

# The mosaic is an analysis aid. The checked-in land-map.png and course.json
# include subsequent start-line alignment and manually reviewed collisions;
# do not overwrite them when running this tool.
