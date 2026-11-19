#!/usr/bin/env python3
"""Mission palette: weighted k-means over the whole course (the brick room
weighs 1.5) and the actors (player and assailants x12, chain and boss x8),
with black (0) and the orange shirt (15) fixed. Prints the per-zone RMS
error and the 16 entries copied into tools/build_mission_visual.py.
Run after make build-mission-visual (reads its course reference)."""
from PIL import Image
import numpy as np, glob
a='assets/mission/'
course=Image.open('build/mission/complete-course-reference.png').convert('RGB')
names=('idle','attack3','jump2','airkick','walk1','walk2','walk3','walk4','enemy-walk1','enemy-walk2','enemy-hit','enemy-fall','enemy-down','player-grab2','player-grab3','orange-walk1','orange-walk2','orange-hit','orange-knee','orange-fall','orange-down')
poses=[Image.open(a+n+'.png').convert('RGBA') for n in names]
extra=[Image.open(f).convert('RGBA') for f in sorted(glob.glob(a+'chain/*.png'))+sorted(glob.glob(a+'boss/*.png'))[:6]]
def pix(img):
    x=np.asarray(img.convert('RGBA')).reshape(-1,4)
    return x[x[:,3]>0][:,:3].astype(float)
def err(px,palette):
    P=np.array(palette,float); d=((px[:,None,:]-P[None])**2).sum(2).min(1); return np.sqrt(d.mean())
zones={'brick':(109,470),'industrial':(500,1354),'pink':(1380,2048)}
zp={z:pix(course.crop((x0,32,x1,212))) for z,(x0,x1) in zones.items()}
sp=np.concatenate([pix(p) for p in poses]); cp=np.concatenate([pix(p) for p in extra])
def report(name,palette):
    print('%-10s'%name,' '.join('%s %.1f'%(z,err(zp[z],palette)) for z in zp),'sprites %.1f chain/boss %.1f'%(err(sp,palette),err(cp,palette)))
# unique colours with weights
def weighted(arrs_w):
    cols={}
    for arr,w in arrs_w:
        u,c=np.unique(arr.astype(int),axis=0,return_counts=True)
        for col,n in zip(map(tuple,u),c): cols[col]=cols.get(col,0)+n*w
    X=np.array(list(cols.keys()),float); W=np.array(list(cols.values()),float); return X,W
def kmeans(X,W,k,fixed,iters=60,seed=0):
    rng=np.random.default_rng(seed)
    C=X[rng.choice(len(X),k,replace=False,p=W/W.sum())]
    F=np.array(fixed,float)
    for _ in range(iters):
        allc=np.vstack([F,C])
        lab=((X[:,None,:]-allc[None])**2).sum(2).argmin(1)
        for j in range(k):
            m=lab==len(F)+j
            if m.any(): C[j]=(X[m]*W[m,None]).sum(0)/W[m].sum()
    return [tuple(map(int,c)) for c in C]
def snap(p): return [(r>>3<<3,g>>3<<3,b>>3<<3) for r,g,b in p]
for ws,wc in ((3,2),):
    X,W=weighted([(zp['brick'],1.5),(zp['industrial'],1),(zp['pink'],1),(sp,ws*4),(cp,wc*4)])
    best=None
    for seed in range(4):
        C=kmeans(X,W,14,[(0,0,0),(232,112,24)],seed=seed)
        new=snap([(0,0,0)]+C+[(232,112,24)])
        score=sum(err(zp[z],new) for z in zp)+err(sp,new)+err(cp,new)
        if best is None or score<best[0]: best=(score,new)
    report('km s%d c%d'%(ws,wc),best[1]); print('   ',best[1])
