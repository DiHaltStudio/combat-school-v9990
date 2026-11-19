#!/usr/bin/env python3
from pathlib import Path
p=Path('build/mission/thrower-test')
def state(n):return list(map(int,(p/f'{n}.txt').read_text().split()))
before,spawn,room,thrown,hit,jumped,orange=(state(n) for n in ('before','spawn','first-room','thrown','hit','jumped','orange-hit'))
assert before[0]==0,before
assert spawn[0]==1,spawn
assert room[1]==0 and room[3]==8,room
assert thrown[1:4]==[1,1,8] and thrown[5]>0,thrown
assert hit[1]==0 and hit[3]==0,(thrown,hit)
assert jumped[3]==8,jumped
assert orange[0] in (2,3,4) and orange[6]==500,orange
print('OK: first-room orange does not throw; future enabled knife hits lethally and a jump avoids it')
