#!/usr/bin/env python3
"""Check the actual GFX9000 screenshots, including the CPU's always-on bar."""
from pathlib import Path
from PIL import Image
frames=sorted(Path('build/demo/frame-capture').glob('*.png'))
assert len(frames)==40, f'expected 40 screenshots, got {len(frames)}'
for path in frames:
 im=Image.open(path).convert('RGB')
 assert im.size==(320,240), f'unexpected screenshot size {im.size}'
 # The POWER legend precedes the CPU's 64px bar, at x75..138.
 for x in (80,100,120,135):
  r,g,b=im.getpixel((x,218))
  assert r>150 and r>g*1.7 and r>b*1.7, f'CPU bar missing in {path.name}'
print('OK: CPU indicator visible in all 40 output screenshots')
