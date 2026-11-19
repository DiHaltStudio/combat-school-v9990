"""Check the displayed page over consecutive frames with multiple actors."""
from pathlib import Path
import os
from PIL import Image

p = Path(os.environ.get('MISSION_TEST_OUT', 'build/mission/page-stability-test'))
atlas = Path('build/mission/atlas-reference.bin').read_bytes()
palette = Path('build/mission/palette.bin').read_bytes()
def pixel(data, x, y):
    b = data[y * 128 + x // 2]
    return b >> 4 if x % 2 == 0 else b & 15

for frame in range(40):
    raw = (p / f'{frame:02d}-vram.bin').read_bytes()
    regs = (p / f'{frame:02d}-regs.bin').read_bytes()
    vram = bytearray(len(raw))
    vram[::2], vram[1::2] = raw[:0x40000], raw[0x40000:]
    screen = vram[(regs[18] & 1) * 32768:]
    ratios = []
    for pose_x in (0, 64, 128):
        expected = matched = 0
        for y in range(64):
            for x in range(64):
                colour = pixel(atlas, pose_x+x, y)
                if colour and 104+y < 212:
                    expected += 1
                    matched += pixel(screen, 96+x, 104+y) == colour
        ratios.append(matched / expected if expected else 0)
    assert max(ratios) > .80, (frame, ratios)
    # Compare the rendered screenshot as well as VRAM: a stable page in VRAM
    # alone does not prove that its scanout was presented without fragments.
    # Skip the initial setup frames while the on-screen view catches up.
    if frame >= 8:
        image = Image.open(p / f'{frame:02d}.png').convert('RGB')
        screenshot_ratios = []
        for pose_x in (0, 64, 128):
            expected = matched = 0
            for y in range(64):
                for x in range(64):
                    colour = pixel(atlas, pose_x+x, y)
                    if not colour:
                        continue
                    rgb = image.getpixel((31+96+x, 13+104+y))
                    error = sum(abs(rgb[j] - palette[3*colour+j]*255/31) for j in range(3))
                    expected += 1
                    matched += error < 60
            screenshot_ratios.append(matched / expected if expected else 0)
        assert max(screenshot_ratios) > .80, (frame, screenshot_ratios)
print('OK: player remains complete through repeated kicks on 40 consecutive frames')
