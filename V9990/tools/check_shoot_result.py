import sys
from pathlib import Path

hits=int(sys.argv[1]); state,seconds,bonus,points,stage=map(int,Path('build/demo/shoot-result.txt').read_text().split())
expected=sum(hits>=boundary for boundary in (48,52,56,60,68))
assert state==(2 if hits>=44 else 3) and seconds==0
assert bonus==expected and points==(0,1000,2000,4000,6000,8000)[expected]
assert stage==4
print(f'OK: {hits} hits, result={state}, bonus={bonus}s/{points} points')
