from pathlib import Path
import sys

case=sys.argv[1]
rows=[list(map(float,line.split())) for line in Path(sys.argv[2]).read_text().splitlines()]
if case=='player_passes':
    assert any(r[6]>0 and r[7]>0 for r in rows), 'CPU was not knocked from bars'
    falling=[r for r in rows if r[6]>0]
    assert max(r[5] for r in falling)>min(r[5] for r in falling), 'CPU did not descend'
    assert any(r[5]<159 and r[15]==48 and r[16]==2816 for r in falling), 'CPU did not use seated pose while descending'
    assert not any(r[3]>0 for r in rows), 'passing player fell'
    assert any(r[5]==159 and r[15]==48 and r[16]==2816 for r in rows), 'CPU did not sit on landing'
elif case=='cpu_passes':
    assert any(r[3]>0 and r[7]>0 for r in rows), 'player was not knocked from bars'
    falling=[r for r in rows if r[3]>0]
    assert max(r[2] for r in falling)>min(r[2] for r in falling), 'player did not descend'
    assert any(r[2]<55 and r[12]==1 and r[13]==0 and r[14]==2816 for r in falling), 'player did not use seated pose while descending'
    assert not any(r[6]>0 for r in rows), 'passing CPU fell'
    assert any(r[2]==55 and r[12]==2 and r[13]==0 and r[14]==2816 for r in rows), 'player did not sit on landing'
else:
    assert not any(r[3]>0 or r[6]>0 or r[7]>0 for r in rows), 'collision with a ground runner'
print(f'OK: {case}')
