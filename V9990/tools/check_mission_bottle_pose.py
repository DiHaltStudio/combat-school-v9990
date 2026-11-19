from pathlib import Path
p=Path('build/mission/bottle-pose-test')
cooldown,health=map(int,(p/'state.txt').read_text().split())
assert 145<=cooldown<=160 and health==8,(cooldown,health)
raw=(p/'vram.bin').read_bytes();regs=(p/'regs.bin').read_bytes()
v=bytearray(len(raw));v[::2],v[1::2]=raw[:0x40000],raw[0x40000:]
screen=v[(regs[18]&1)*32768:];src=Path('build/mission/hang-reference.bin').read_bytes()
def pixel(data,x,y):
    a=data[y*128+x//2]
    return a>>4 if x%2==0 else a&15
matched=total=0
for y in range(8,64):
    for x in range(17,47):
        color=pixel(src,64+x,80+y)
        if color:
            total+=1
            matched+=pixel(screen,171+x,136+y)==color
assert total>100 and matched/total>.8,(matched,total)
print(f'OK: captured orange throwing pose displayed ({matched}/{total} pixels)')
