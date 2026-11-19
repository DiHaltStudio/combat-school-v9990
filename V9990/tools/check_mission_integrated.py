"""Final mission in the game MegaROM (tools/test_mission_integrated.tcl):
after the Step 7 victory, the rank screen, the two screens before the
mission and the mission itself, at its starting camera; with
MISSION_ENDING also the arcade ending and the title (directory argument)."""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
p=Path(sys.argv[1] if len(sys.argv)>1 else 'build/mission/integrated-test')
rank,attention,mansion,mission,camera=map(int,(p/'path.txt').read_text().split())
assert (rank,attention,mansion,mission)==(1,1,1,1),(rank,attention,mansion,mission)
assert camera>=1700,camera
for name in ('rank','attention','mansion','mission'):
    assert (p/f'{name}.png').exists(),name
print(f'OK: Step 7 victory, rank screen, ATTENTION, mansion and the mission (camera {camera})')
if (p/'ending.txt').exists():
    # test-mission-integrated-ending: the arcade ending, then the title.
    score,c,s_,first=map(int,(p/'ending.txt').read_text().split())
    assert 200000<=score<400000,('the game score reaches the mission',score)
    assert (c,s_)==(ord('C'),ord('S')),'RANKING table kept in F300'
    title=np.asarray(Image.open(p/'title.png').convert('RGB'))[13:225,31:287]
    assert title.max()>64,'a picture after the ending'
    print(f'OK: ending with the game score {score} (first in RANKING {first}), then the title')
