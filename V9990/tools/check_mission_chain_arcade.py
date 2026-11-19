#!/usr/bin/env python3
"""Check actual arcade state changes; no writes to the chain actor are used."""
from pathlib import Path
base=Path('build/mission/chain-hit')
transitions=[]; scores=[]; last=None
for p in sorted(base.glob('frame-*/ram.bin')):
    r=p.read_bytes()
    assert len(r)==0x1800
    kind=r[0x4b0] # X+$10, X=$0ca0
    if kind!=last:
        transitions.append(kind);last=kind
    score=int(r[0x20:0x23].hex())*10
    if not scores or score!=scores[-1]:scores.append(score)
assert transitions==[7,8,10,9],transitions
assert len(scores)==3 and scores[1]-scores[0]==scores[2]-scores[1]==500,scores
last=sorted(base.glob('frame-*/ram.bin'))[-1].read_bytes()
assert last[0x4b0]==9 and last[0x491]==2, 'did not remain down'
print('OK arcade chain: approach(7), first hit(8), wounded(10), final fall(9); two hits, +500 each')
