from pathlib import Path
from PIL import Image

out = Path('build/step4/blink')
assert list(map(int, (out/'result.txt').read_text().split())) == [0, 8]
a = Image.open(out/'a.png').convert('RGB')
b = Image.open(out/'b.png').convert('RGB')
changes = [(x, y, a.getpixel((x,y)), b.getpixel((x,y)))
           for y in range(a.height) for x in range(a.width)
           if a.getpixel((x,y)) != b.getpixel((x,y)) and not 29 <= y < 39]
# The clock (game y 16..25, raw +13) shows tenths and is left out. The large
# side robot at game (100,110) is 26x24 (raw offsets 31,13).
assert changes and all(131 <= x < 157 and 123 <= y < 147 for x,y,_,_ in changes), changes[:5]
assert len({(bright, dark) for _,_,bright,dark in changes}) == 1
bright, dark = changes[0][2:]
assert bright[0] > dark[0] and bright[2] > dark[2], (bright, dark)
print('OK: only the robot panel changes from bright pink to dark purple')
