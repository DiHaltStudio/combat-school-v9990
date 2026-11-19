from pathlib import Path
from PIL import Image
p=Path('build/mission/fire-approach-test')
def orange(name):
    im=Image.open(p/f'{name}.png').convert('RGB')
    return sum(1 for r,g,b in im.crop((31,160,100,220)).getdata()
               if r>200 and 80<g<170 and b<80)
for name in ('before','partial','full'):
    state=list(map(int,(p/f'{name}.txt').read_text().split()))
    assert state[0]==1 and state[2]==8,(name,state)
counts=list(map(orange,('before','partial','full')))
assert counts[1]>0 and counts[2]>0,counts
print('OK: the initial fire survives an early bottle and enters progressively:',counts)
