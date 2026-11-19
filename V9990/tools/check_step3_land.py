"""Check both cameras use the same world and the land course changes."""
from pathlib import Path
from PIL import Image, ImageChops

folder=Path('build/step3/land-test')
images=[Image.open(folder/f'{name}.png').convert('RGB') for name in ('early','bridge','later')]
for im in images:
    # The upper part avoids the clock, actors and POWER indicators.
    left=im.crop((39,35,135,75))
    right=im.crop((167,35,263,75))
    assert ImageChops.difference(left,right).getbbox() is None, 'cameras disagree on same world position'
areas=[im.crop((39,35,135,75)) for im in images]
assert ImageChops.difference(areas[0],areas[2]).getbbox(), 'land repeats after 256 pixels'
assert ImageChops.difference(areas[0],areas[1]).getbbox(), 'bridge section does not differ from start'
print('OK: shared cameras and distinct sections of land')
