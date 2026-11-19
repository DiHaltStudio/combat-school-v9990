#!/usr/bin/env python3
"""Verify retained race data and the actual V9990 bonus/map screens."""
import sys
from pathlib import Path

folder=Path(sys.argv[1]); remaining=int(sys.argv[2]); cpu=int(sys.argv[3])
frames=Path('build/demo/progress.bin').read_bytes()
bonus=min(remaining//2,5)
observed_maps=[]
for name,frame in (('bonus',bonus),('map',None),('map-other',None)):
    memory=(folder/f'{name}-memory.bin').read_bytes()
    assert memory[0xc410]==remaining and memory[0xc411]==0
    assert memory[0xc412]==1 and memory[0xc413]==bonus
    assert memory[0xc414]+256*memory[0xc415]==(0,1000,2000,4000,6000,8000)[bonus]
    assert memory[0xc416]==cpu and memory[0xc417]==35+bonus
    assert memory[0xc0d9]==(2 if cpu else 1)
    phys=(folder/f'{name}-vram.bin').read_bytes()
    regs=(folder/f'{name}-regs.bin').read_bytes()
    pal=(folder/f'{name}-pal.bin').read_bytes()
    logical=bytearray(len(phys));logical[::2]=phys[:0x40000];logical[1::2]=phys[0x40000:]
    start=(regs[18]&1)*32768
    shown=logical[start:start+27136]
    if frame is None:
        assert shown in (frames[6*32768:6*32768+27136],frames[7*32768:7*32768+27136])
        observed_maps.append(shown)
    else: assert shown==frames[frame*32768:frame*32768+27136]
    palette='map-palette.bin' if frame is None else 'progress-palette.bin'
    assert b''.join(pal[i*4:i*4+3] for i in range(16))==Path('build/demo',palette).read_bytes()
assert observed_maps[0]!=observed_maps[1], 'completed step did not blink'
print(f'OK: {remaining}s remaining, +{bonus}s, CPU first={cpu}, bonus and map')
