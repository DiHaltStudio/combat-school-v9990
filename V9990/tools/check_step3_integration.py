#!/usr/bin/env python3
"""Check shooting -> bonus -> map -> relocated Step 3 in the real ROM."""
import sys
from pathlib import Path
from PIL import Image
folder=Path(sys.argv[1])
hits=int(sys.argv[2])
bonus=2 if hits==52 else 5
seen_bonus,seen_map,stage,actual_bonus,seconds,points,start,end,wading,fall=map(int,(folder/'result.txt').read_text().split())
assert (seen_bonus,seen_map,stage,actual_bonus)==(1,1,7,bonus)
assert 45+bonus-2<=seconds<=45+bonus, (bonus,seconds)
assert points==4000+[0,1000,2000,4000,6000,8000][bonus], points
assert end>start, (start,end)
assert (wading,fall)==(1,0), (wading,fall)
im=Image.open(folder/'screen.png').convert('RGB')
assert len(im.getcolors(im.width*im.height))>8
print('OK: shooting result, map, bonus and playable Step 3',hits,seconds,points,end)
