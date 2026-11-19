#!/usr/bin/env python3
"""Complete the reconstructed Step 1 course with arcade parts missing from it.

course-reconstruction.png only contains the K007121 tile planes captured while
the player was still before the goal, so it lacks:
  * the front diagonal posts of the monkey bars and their ground plates, which
    the arcade draws as sprites at the entry and at the exit of the bars;
  * the goal scenery (end of the fence, road, hut and gate).
Both are taken from captures of the same arcade ROM (tools/mame_finish_capture.lua).
Every capture is placed in course coordinates by matching its rendered
background plane against the reconstruction.
"""
import subprocess, sys
from pathlib import Path
import numpy as np
from PIL import Image

out_dir = Path('build/course-analysis')
course = np.asarray(Image.open(out_dir / 'course-reconstruction.png').convert('RGB')).copy()
tmp = Path('build/course-analysis/finish-planes')

def capture(root, frame):
    root = Path(root)
    frames = sorted(root.glob('frame-*'))
    index = [f.name for f in frames].index(f'frame-{frame:04d}')
    shot = sorted((root / 'combatsc').glob('*.png'))[index]
    subprocess.run([sys.executable, 'tools/render_background.py', str(root / f'frame-{frame:04d}'),
                    '--vreg', '0x33', '--out', str(tmp)], check=True, stdout=subprocess.DEVNULL)
    snap = np.asarray(Image.open(shot).convert('RGB')).astype(int)
    planes = []
    for name, alpha in (('plane1', False), ('plane0', True)):
        plane = np.asarray(Image.open(tmp / f'{name}.png').convert('RGBA')).astype(int)
        scores = []
        for shift in range(256):
            c = np.roll(plane, -shift, axis=1)[25:100, 8:248]
            mask = c[:, :, 3] > 0 if alpha else np.ones(c.shape[:2], bool)
            diff = np.any(c[:, :, :3] != snap[25:100, 8:248], axis=2)
            scores.append(diff[mask].mean() if mask.sum() > 80 else 1.0)
        planes.append(np.roll(plane, -int(np.argmin(scores)), axis=1))
    composed = planes[0].copy()
    fg = planes[1][:, :, 3] > 0
    composed[fg] = planes[1][fg]
    return snap, composed[:, :, :3]

def world_x(composed, lo, hi):
    """Course column shown at screen x=0, from the mountains and fence band."""
    best = min(range(lo, hi), key=lambda x: np.any(
        course[25:100, x + 8:x + 248] != composed[25:100, 8:248], axis=2).mean())
    return best

def post_pixels(sprite, snap, box):
    """Sprite pixels of the post inside box; the red timer is excluded by colour."""
    x0, y0, x1, y1 = box
    keep = np.zeros_like(sprite)
    keep[y0:y1, x0:x1] = True
    green = (snap[:, :, 1] > snap[:, :, 0] + 8) & (snap[:, :, 1] >= snap[:, :, 2])
    # (33,66,33) is also the drop shadow of the timer digits above the post.
    shadow = np.all(snap == (33, 66, 33), axis=2)
    shadow[40:] = False
    return sprite & keep & green & ~shadow

# Front posts of the monkey bars: sprite pixels of a capture without runner overlap.
# Boxes are screen coordinates that contain the post but not the runner.
for root, frame, lo, hi, box in (('build/mame-bars-entry', 2236, 1700, 2300, (185, 28, 248, 112)),
                                 ('build/mame-finish', 2628, 2100, 2505, (155, 28, 224, 112))):
    snap, composed = capture(root, frame)
    sprite = np.any(snap != composed, axis=2)
    post = post_pixels(sprite, snap, box)
    cam = world_x(composed, lo, hi)
    ys, xs = np.nonzero(post)
    print(f'{root} {frame}: camera {cam}, post x {xs.min()}..{xs.max()} y {ys.min()}..{ys.max()}, {len(xs)} px')
    course[ys, xs + cam] = snap[ys, xs]

# Goal scenery: the player's lane once the camera has stopped at the goal.
snap, composed = capture('build/mame-finish', 3000)
# The ROM camera stops at course x 2488 (reconstruction x 2496, the ROM drops
# its first 8 columns); place the arcade's final view exactly there.
cam = 2496
print(f'goal view at course x {cam} (image match suggests {world_x(composed, 2300, course.shape[1] - 255)})')
# Keep the reconstruction up to the first fence post of the goal view so the
# seam falls on a post; replace everything from there to the end.
seam = 8
course[:112, cam + seam:cam + 256] = composed[:112, seam:256]
Image.fromarray(course).save(out_dir / 'course-finished.png')
