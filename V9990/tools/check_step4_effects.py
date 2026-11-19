from pathlib import Path
from PIL import Image

out=Path('build/step4/effects')
remaining,final,hits,marked=map(int,(out/'result.txt').read_text().split())
assert 0<remaining<=12 and final==0 and hits==1 and marked==1
im=Image.open(out/'blast.png').convert('RGB')
# Robot at game (80,40); raw screenshot has 31,13 border offsets.
region=im.crop((111,53,127,69))
red=sum(r>175 and g<100 and b<100 for r,g,b in region.getdata())
white=sum(r>200 and g>200 and b>180 for r,g,b in region.getdata())
assert red and white, (red,white)
# Shooter strip at VRAM y 724..783: field lines 212..255 and atlas lines 0..15.
field=Path('build/step4/field.bin').read_bytes()
data=Path('build/step4/atlas.bin').read_bytes()
def get(x,y):
 source,y=(field,y+212) if y<44 else (data,y-44)
 v=source[(y*256+x)//2]
 return (v>>4) if x%2==0 else (v&15)
def pose(x):
 return tuple(get(x+a,b) for b in range(60) for a in range(32))
poses=[pose(x) for x in range(0,224,32)]
assert len(set(poses))==7
assert all(any(p) for p in poses)
print('OK: seven arcade shooter poses and a temporary hit explosion')
