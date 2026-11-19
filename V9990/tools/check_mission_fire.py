from pathlib import Path
from PIL import Image

p = Path('build/mission/fire-test')
def read(name):
    return list(map(int, (p / f'{name}.txt').read_text().split()))
landed, expired, elevated, hit = map(read, ('landed', 'expired', 'elevated', 'hit'))
assert landed[0] == 2 and landed[1] == 8 and landed[2] > 0, landed
assert expired[0] == 0 and expired[1] == 8, expired
assert elevated[0] == 2 and elevated[1] == 8, elevated
assert hit[1] == 0, hit
# Check the actual screenshot against the 32x48 arcade-derived sprite. The
# test scene keeps the player away from the impact and uses a fixed camera.
extra = Path('build/mission/extra-reference.bin').read_bytes()
palette = Path('build/mission/palette.bin').read_bytes()
image = Image.open(p/'fire.png').convert('RGB')
expected = matched = 0
for y in range(48):
    for x in range(32):
        byte = extra[(416+y)*128+(160+x)//2]
        colour = byte >> 4 if x%2==0 else byte&15
        if not colour:
            continue
        rgb = image.getpixel((31+28+x, 13+152+y))
        error = sum(abs(rgb[j]-palette[colour*3+j]*255/31) for j in range(3))
        expected += 1
        matched += error < 60
assert expected > 250 and matched / expected > .85, (expected, matched)
print('OK: arcade-sized fire renders, expires and damages on contact')
