"""Loop intervals of tools/test_mission_walk_timing.tcl: one display frame
per loop (no interval above 25 ms), overall and with the doorway in view."""
import sys
from pathlib import Path
p=Path(sys.argv[1] if len(sys.argv)>1 else 'build/mission/walk-timing-test')
# Camera range with the doorway in view (default: pink room doorway).
lo,hi=(int(sys.argv[2]),int(sys.argv[3])) if len(sys.argv)>3 else (1099,1362)
rows=[l.split() for l in (p/'timing.txt').read_text().splitlines()]
t=[(float(r[1]),int(r[2])) for r in rows]
d=[(b[0]-a[0],b[1]) for a,b in zip(t[5:],t[6:])]
door=[x for x,c in d if lo<=c<hi]
slow=[x for x,_ in d if x>0.025]
print(f'{len(d)} loops, camera {t[5][1]}..{min(c for _,c in t)}; mean {1000*sum(x for x,_ in d)/len(d):.2f} ms, max {1000*max(x for x,_ in d):.2f} ms; '
      f'doorway in view {len(door)} loops, max {1000*max(door):.2f} ms; dropped frames {len(slow)}')
# Spare time: from the end of the drawing to the next loop (vertical blank).
spare=[(float(b[1])-float(b[4]),int(a[2])) for a,b in zip(rows[5:],rows[6:]) if len(b)>4 and float(b[4])>0 and float(b[1])-float(a[1])<0.025]
if spare:
    print(f'spare time: min {1000*min(x for x,_ in spare):.2f} ms overall, min {1000*min([x for x,c in spare if lo<=c<hi] or [0]):.2f} ms with the doorway in view')
assert len(door)>100,len(door)
assert not slow,[round(x*1000,2) for x in slow[:10]]
print('OK: one display frame per loop on the walk through the doorway')
