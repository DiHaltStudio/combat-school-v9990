"""Chain assailant entry (tools/test_mission_chain_entry.tcl), as in the arcade:
appears at camera < 272 outside the left edge (origin 228, centre 260),
walks in, holds the camera at 258 while up, releases it when down."""
from pathlib import Path
rows=[tuple(map(int,l.split())) for l in Path('build/mission/chain-entry-test/log.txt').read_text().splitlines()]
spawn=next(r for r in rows if r[2])
n,cam,state,origin=spawn
assert cam<272 and origin==228,spawn
assert origin+32<cam,('visible at once',spawn)
alive=[r for r in rows if 1<=r[2]<=4]
assert min(r[1] for r in alive)==258,min(r[1] for r in alive)
assert max(r[3] for r in alive)>origin+20,('did not walk in',max(r[3] for r in alive))
down=[r for r in rows if r[2]==5]
assert down and min(r[1] for r in down)<250,('camera did not move on',down[-1:])
jump=max(abs(b[1]-a[1]) for a,b in zip(rows,rows[1:]) if a[0]>2)
assert jump<=2,('camera jump',jump)
print(f'OK: appears at camera {cam} outside the left edge, walks in, camera held at 258 while up and released when down (at most {jump} px per update)')
