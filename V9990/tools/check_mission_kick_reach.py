"""Kick reach of tools/test_mission_kick_reach.tcl: the arcade kick hits up
to 32 px between centres and misses from 33 (tools/mame_mission_kick_reach.lua)."""
from pathlib import Path
r={d:Path(f'build/mission/kick-reach-{d}/result.txt').read_text().split()[1] for d in (20,32,34,40)}
assert r=={20:'1',32:'1',34:'0',40:'0'},r
print('OK: the kick reaches 32 px as in the arcade (hit at 20 and 32, miss at 34 and 40)')
