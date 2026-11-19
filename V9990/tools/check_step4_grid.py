from pathlib import Path
from PIL import Image
root=Path('build/step4/grid')
def reds(name, box):
    im=Image.open(root/f'{name}.png').convert('RGB')
    return sum(r>180 and g<80 and b<80 for r,g,b in im.crop(box).getdata())
# raw GFX9000 output has an origin at (31,13).
rows=(39,210,143,216)
extra=(39,218,143,221)
a,b=reds('empty',rows),reds('qualified',rows)
c,d=reds('qualified',extra),reds('bonus',extra)
assert b>a+100 and d>c, (a,b,c,d)
# Label ends above the first row and does not extend into the grid.
label = reds('empty', (39,204,66,209))
space = reds('empty', (39,209,143,210))
assert label > 25 and space == 0, (label,space)
print('OK: two qualifying rows and individual bonus squares',a,b,c,d)
