from pathlib import Path
from PIL import Image
p=Path('build/mission/enemy-entry-test')
def orange(camera):
    im=Image.open(p/f'{camera}.png').convert('RGB')
    return sum(1 for r,g,b in im.crop((31,150,100,205)).getdata()
               if r>130 and r>g*1.3 and g>b*1.2)
states={n:list(map(int,(p/f'{n}.txt').read_text().split())) for n in (710,707,700,690,680)}
assert states[710]==[0,8] and all(states[n]==[1,8] for n in (707,700,690,680)),states
counts=[orange(n) for n in (710,700,690,680)]
assert counts[0]==0 and 0<counts[1]<counts[2]<counts[3],counts
print('OK: enemy activates as crate enters and artwork appears progressively at the edge:',counts)
