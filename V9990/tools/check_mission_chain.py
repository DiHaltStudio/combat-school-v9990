"""Check clipped chain poses against actual source pixels and frame timings."""
from pathlib import Path
import json,struct
p=Path('build/mission/chain-test')
desc=json.loads(Path('build/mission/chain-descriptors.json').read_text())
def pixel(data,x,y):
    b=data[y*128+x//2];return b>>4 if x%2==0 else b&15
count=0
for n in range(24):
    raw=(p/f'{n}-vram.bin').read_bytes();v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
    regs=(p/f'{n}-regs.bin').read_bytes();ram=(p/f'{n}-ram.bin').read_bytes()
    pose,face=ram[0x17f],ram[0x178]
    world=struct.unpack_from('<H',ram,0x172)[0]
    cam=struct.unpack_from('<H',ram,0x40)[0];page=regs[18]&1
    for sx,sy,w,h,dx,dy in desc[pose*2+face]['pieces']:
        for y in range(h):
            for x in range(w):
                expected=pixel(v,sx+x,sy+y)
                screenx=world+dx+x-cam;screeny=136+dy+y
                if not expected or not 0<=screenx<256:continue
                # The player is drawn last and can occlude the chain.
                if 96<=screenx<160 and 136<=screeny<200:continue
                address=(page*256+regs[17]+screeny)*256+screenx+(cam&255)
                actual=pixel(v,address%256,address//256)
                assert actual==expected,(n,pose,face,screenx,screeny,actual,expected)
                count+=1
assert count>7000,count
lines=[list(map(float,x.split())) for x in (p/'timing.txt').read_text().splitlines()]
# Frames 351/352 rebuild both pages after the test-only camera teleport.
# Keep every gameplay interval, including the loaded scroll and approach.
deltas=[b[1]-a[1] for a,b in zip(lines[5:],lines[6:]) if int(b[0]) not in (351,352)]
assert max(deltas)<.025,max(deltas)
print(f'OK: {count} opaque pixels in 24 pose/facing/edge cases; max frame {max(deltas)*1000:.2f} ms')
