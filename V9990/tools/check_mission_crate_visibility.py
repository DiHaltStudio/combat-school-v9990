from pathlib import Path
from PIL import Image
p=Path('build/mission/crate-visibility-test')
counts=[]
for i in range(8,60):
    image=Image.open(p/f'{i:02}.png').convert('RGB')
    count=sum(1 for r,g,b in image.crop((85,158,125,215)).getdata()
              if b>g+15 and b>r+50 and b>110)
    counts.append(count)
    assert count>=70,(i,count)
print(f'OK: blue enemy remains visible in 52 consecutive frames (minimum {min(counts)} blue pixels)')
