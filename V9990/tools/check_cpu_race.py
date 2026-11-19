#!/usr/bin/env python3
from pathlib import Path
rows=[list(map(float,line.split())) for line in Path('build/demo/cpu-race.log').read_text().splitlines()]
assert rows and any(r[3]>0 for r in rows), 'CPU did not jump'
assert any(r[4]>0 for r in rows), 'CPU did not reach the bars'
assert any(r[5]==1 and r[7]==0 for r in rows), 'CPU did not finish while the player continued'
# The first race only: after GAME OVER and the RANKING a new race starts.
first_end=next((i for i,r in enumerate(rows) if r[7]==3),len(rows))
finished=[r for r in rows[:first_end] if r[5]==1 and r[7]==0]
assert len(finished)>2 and len({r[8] for r in finished[1:]})==1, 'CPU animation continued after reaching the finish'
assert all(r[9]==176 for r in finished[1:]), 'CPU did not show the resting pose'
timeout=[i for i,r in enumerate(rows) if r[7]==3]
assert timeout, 'race did not end when the player ran out of time'
# Lost without penalty (far from the goal): GAME OVER, the title and, as the
# test presses space there, a new race.
assert any(r[7]==0 for r in rows[timeout[-1]:]), 'the lost race did not end the game'
print('OK: CPU crossed the route, jumped, used bars and reached its result; the lost race ends the game')
