#!/usr/bin/env python3
"""Extract a synchronized, consistently anchored run cycle from MAME video.

Run extract_step3_cycle.sh VIDEO first. Outputs are checked-in assets; the
video itself is not needed by the normal build. Alpha masks are approximate
because the source is a scaled recording, not native arcade sprite memory.
"""
from pathlib import Path
from PIL import Image, ImageDraw

source=Path('build/step3-analysis/mame')
out=Path('assets/step3')
out.mkdir(parents=True,exist_ok=True)

def extract(frame, box, output):
    image=Image.open(frame).convert('RGBA').crop(box)
    w,h=image.size
    mask=Image.new('L',(w,h))
    d=ImageDraw.Draw(mask)
    # Shared source coordinates keep the head and the ground contact fixed.
    d.polygon([(int(x*w),int(y*h)) for x,y in (
        (.25,.02),(.75,.02),(.80,.14),(.96,.24),(1,.39),(.88,.49),
        (.75,.43),(.82,.55),(.84,1),(.16,1),(.18,.55),(.25,.43),
        (.12,.49),(0,.39),(.04,.24),(.20,.14))],fill=255)
    image.putalpha(mask)
    px=image.load()
    for y in range(h):
        for x in range(w):
            r,g,b,a=px[x,y]
            # Hair and shaded skin are brown too; only discard the lighter
            # sand tones, preserving the darker outline of the head.
            sand=(r>155 and g>115 and b>85 and 10<r-g<55 and 10<g-b<55)
            trouser=(g > r*.86 and g > b*1.04 and g < 165)
            if a and (sand or (y>=h*.48 and not trouser)):
                px[x,y]=(r,g,b,0)
    image.resize((24,32),Image.Resampling.LANCZOS).save(output)

for index,frame in enumerate((11,13,16,18)):
    path=source/f'{frame:02}.png'
    extract(path,(505,525,665,735),out/f'run-cycle-player-{index}.png')
    extract(path,(1000,525,1160,735),out/f'run-cycle-cpu-{index}.png')
