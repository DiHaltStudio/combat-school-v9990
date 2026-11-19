import json
from pathlib import Path

from PIL import Image

# Side views from target-sets.bin (row, then width, x, height per size).
# In the arcade capture the unflipped side sprite travels right (82 of 83
# measured moves), so orientation 1 (right) must be the unflipped arcade
# image and orientation 2 (left) its mirror. Colour 11 is the magenta panel.
atlas = Path('build/step4/atlas.bin').read_bytes()
sets = Path('build/step4/target-sets.bin').read_bytes()
def pixel(x, y):
    byte = atlas[(y * 256 + x) // 2]
    return byte >> 4 if x % 2 == 0 else byte & 15

def panel_x(view, band=3):
    row = sets[view * 16]
    w, x0, h = sets[view * 16 + 1 + band * 3:view * 16 + 4 + band * 3]
    xs = [x for y in range(h) for x in range(w) if pixel(x0 + x, row + y) == 11]
    assert xs, (view, 'panel missing')
    return sum(xs) / len(xs) / w

arcade = Image.open('assets/step4/arcade-targets.png').convert('RGBA').crop((96, 32, 128, 64))
arcade = arcade.crop(arcade.getbbox())
magenta = [x for y in range(arcade.height) for x in range(arcade.width)
           if arcade.getpixel((x, y)) == (214, 0, 132, 255)]
expected = sum(magenta) / len(magenta) / arcade.width
right, left = panel_x(1), panel_x(2)
assert abs(right - expected) < 0.05 and abs(left - (1 - expected)) < 0.1, (right, left, expected)

# Check actual playback, not only atlas locations: in the MAME recording
# (tools/build_step4_robots.py) a robot in side view 1 moves right and in
# view 2 moves left.
data = Path('build/step4/recorded-sequence.bin').read_bytes()[:json.loads(Path('assets/step4/recorded-sequence.json').read_text())['bytes']]
pos = 0
tracks = {}
for frame in range(1380):
    count = data[pos]
    pos += 1
    for _ in range(count):
        ident, x, y, view = data[pos:pos+4]
        view &= 3                         # bits 2-4: size + 1
        pos += 4
        tracks.setdefault(ident, []).append((frame, x, view))
good = bad = 0
for samples in tracks.values():
    for a, b in zip(samples, samples[1:]):
        if b[0] == a[0] + 1 and abs(b[1] - a[1]) >= 2 and a[2] in (1, 2):
            if (a[2] == 1) == (b[1] > a[1]):
                good += 1
            else:
                bad += 1
assert good > 1000 and bad < good / 100, (good, bad)
print('OK: side views face the direction of the recorded robots')
