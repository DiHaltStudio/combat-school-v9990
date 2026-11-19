"""Check clipped chain poses against actual source pixels and frame timings."""
from pathlib import Path
import json,struct
p=Path('build/mission/boss-test')
desc=json.loads(Path('build/mission/boss-descriptors.json').read_text())
def pixel(data,x,y):
    b=data[y*128+x//2];return b>>4 if x%2==0 else b&15
count=0
for n in range(22):
    raw=(p/f'{n}-vram.bin').read_bytes();v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
    regs=(p/f'{n}-regs.bin').read_bytes();ram=(p/f'{n}-ram.bin').read_bytes()
    pose,face=ram[0x18f],ram[0x188]
    world=struct.unpack_from('<H',ram,0x182)[0]
    cam=struct.unpack_from('<H',ram,0x40)[0];page=regs[18]&1
    for sx,sy,w,h,dx,dy in desc[pose*2+face]['pieces']:
        for y in range(h):
            for x in range(w):
                expected=pixel(v,sx+x,sy+y)
                screenx=world+dx+x-cam;screeny=136+dy+y
                if not expected or not 0<=screenx<256:continue
                # The player is drawn last and can occlude the chain.
                if 190<=screenx<254 and 136<=screeny<200:continue
                address=(page*256+regs[17]+screeny)*256+screenx+(cam&255)
                actual=pixel(v,address%256,address//256)
                assert actual==expected,(n,pose,face,screenx,screeny,actual,expected)
                count+=1
assert count>7000,count
lines=[list(map(float,x.split())) for x in (p/'timing.txt').read_text().splitlines()]
deltas=[b[1]-a[1] for a,b in zip(lines[5:],lines[6:])]
assert max(deltas)<.025,max(deltas)
print(f'OK: {count} opaque pixels in 22 boss pose/facing cases; max frame {max(deltas)*1000:.2f} ms')

for n in (10,24,104,264,344,504,584,744,824):
    raw=(p/f'hud-{n}-vram.bin').read_bytes();v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
    regs=(p/f'hud-{n}-regs.bin').read_bytes();ram=(p/f'hud-{n}-ram.bin').read_bytes()
    page=regs[18]&1;cam=struct.unpack_from('<H',ram,0x40)[0]
    sy=2448+(8-ram[0x186])*8
    for y in range(8):
        for x in range(112):
            assert pixel(v,cam%256+x,page*256+cam//256+24+y)==pixel(v,x,sy+y),(n,'guardian DAMAGE',x,y)
print('OK: complete guardian DAMAGE cells at every health value')
