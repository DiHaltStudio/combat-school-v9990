#!/usr/bin/env python3
"""Check start signal, frozen countdown and the goal instructor's gesture."""
from pathlib import Path

rows = [list(map(float, line.split())) for line in Path('build/demo/instructor-trace.txt').read_text().splitlines()]
ready = [r for r in rows if r[1] == 1 and r[5] == 3]
assert ready and {0, 1} <= {int(r[6]) for r in ready}, 'missing starter poses'
assert all(r[2] == 35 and r[3] == 64 and r[4] == 64 for r in ready), 'race moved before signal'
goal = [r for r in rows if r[7] == 1 and int(r[5]) & 1]
# Arcade gesture at the goal: arms crossed (3), baton raised (5), pointing (4).
assert goal and {3, 4, 5} <= {int(r[6]) for r in goal}, 'missing goal instructor gesture'
assert any(r[1] == 0 and r[4] > 64 for r in rows), 'CPU did not start'
print('OK: starter signal, frozen countdown, winner and goal gesture')
