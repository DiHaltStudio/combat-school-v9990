import sys
from pathlib import Path

p=Path(sys.argv[1]);hits=int(sys.argv[2])
bonus=sum(hits>=n for n in (48,52,56,60,68))
frames=Path('build/demo/shoot-progress.bin').read_bytes()
maps=[]
for name,index in (('bonus',bonus),('map',None),('map-other',None)):
    memory=(p/f'{name}-memory.bin').read_bytes()
    assert memory[0xc434]==hits and memory[0xc43a]==2 and memory[0xc43f]==bonus
    assert memory[0xc440]+256*memory[0xc441]==(0,1000,2000,4000,6000,8000)[bonus]
    phys=(p/f'{name}-vram.bin').read_bytes();regs=(p/f'{name}-regs.bin').read_bytes();pal=(p/f'{name}-pal.bin').read_bytes()
    v=bytearray(len(phys));v[::2]=phys[:0x40000];v[1::2]=phys[0x40000:]
    start=(regs[18]&1)*32768;shown=v[start:start+27136]
    if index is None:
        assert shown in (frames[6*32768:6*32768+27136],frames[7*32768:7*32768+27136]);maps.append(shown)
    else: assert shown==frames[index*32768:index*32768+27136]
    palette='map-palette.bin' if index is None else 'progress-palette.bin'
    assert b''.join(pal[i*4:i*4+3] for i in range(16))==Path('build/demo',palette).read_bytes()
assert maps[0]!=maps[1]
def pixel(image,x,y):
    byte=image[y*128+x//2]
    return byte>>4 if x%2==0 else byte&15
assert pixel(maps[0],20,160)!=pixel(maps[1],20,160)
assert pixel(maps[0],20,200)!=pixel(maps[1],20,200)
print(f'OK: {hits} hits, shooting bonus and two-step blinking map')
