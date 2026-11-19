#!/usr/bin/env python3
"""Align captured arcade background planes and stitch the first room."""
from pathlib import Path
import os
from PIL import Image,ImageChops,ImageStat
import subprocess

root=Path('build/mission')
capture_name=os.getenv('MISSION_COURSE_CAPTURE','course-mame')
capture_root=root/capture_name
captures=sorted(capture_root.glob('frame-*'))
assert len(captures)>=2,'run make capture-mission-course first'
screenshots=sorted((capture_root/'combatsc').glob('*.png'))
assert len(screenshots)>=len(captures),'missing captured screenshots'
screenshots=screenshots[-len(captures):]
frames=[]
for index,path in enumerate(captures):
    folder=root/('course-planes' if capture_name=='course-mame' else capture_name+'-planes')/path.name
    subprocess.run(['python3','tools/render_background.py',str(path),'--out',str(folder)],check=True)
    plane=Image.open(folder/'plane1.png').convert('RGB')
    screenshot=Image.open(screenshots[index]).convert('RGB')
    reference=screenshot.crop((8,30,248,134))
    best=None
    # The saved plane is circular. Match the actual screenshot to recover
    # its horizontal offset; cap error so passing actors do not dominate it.
    for shift in range(256):
        rolled=Image.new('RGB',plane.size)
        rolled.paste(plane,(shift,0));rolled.paste(plane,(shift-256,0))
        diff=ImageChops.difference(reference,rolled.crop((8,30,248,134)))
        diff=diff.point([min(i,60) for i in range(256)]*3)
        score=sum(ImageStat.Stat(diff).sum)
        if best is None or score<best[0]:best=(score,shift,rolled)
    assert best[0]/(240*104)<45,(path.name,'background could not be aligned')
    world=int((path/'world.txt').read_text())
    frames.append((world,best[2]))
low=min(w for w,_ in frames);high=max(w for w,_ in frames)
course=Image.new('RGB',(high-low+256,212))
for world,frame in frames:
    course.paste(frame.crop((0,0,256,212)),(world-low,0))
out=Path(os.getenv('MISSION_COURSE_OUTPUT','assets/mission/course-first-room.png'));out.parent.mkdir(parents=True,exist_ok=True)
course.save(out)
print(f'{out}: {course.width}x{course.height}, sampled world {low}–{high}')
