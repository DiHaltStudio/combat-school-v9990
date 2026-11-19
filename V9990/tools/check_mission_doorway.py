#!/usr/bin/env python3
"""Verify doorway entry, arcing knife and fatal impact with no setup cheats."""
from pathlib import Path
p=Path('build/mission/doorway-test')
def state(name):return [int(x) for x in (p/f'{name}.txt').read_text().split()]
before,after,start,rise,impact=(state(n) for n in ('before','after','projectile-start','projectile-rise','impact'))
windup=state('windup')
assert (p/'initial-facing.txt').read_text().strip()=='1'
assert before[0]==0 and before[2]==0 and before[4]==8,before
assert after[0]==1 and after[4]==8,after
assert start[2]==1 and rise[2]==1 and rise[3]==start[3] and start[6]==1,(start,rise)
assert windup[2]==0 and windup[7]>=165 and start[7]>=150,(windup,start)
assert impact[4]==0,impact
print('OK: doorway attacker throws a knife and defeats the player on contact')
