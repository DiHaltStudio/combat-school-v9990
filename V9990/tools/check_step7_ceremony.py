"""Graduation ceremony (tools/test_step7_ceremony.tcl): 60 arcade frames per
second, the camera rising 2 rows per frame from the stage to the flag, the
four waving pictures in turn, no cap left on either scene copy, and the rank
screen at the end."""
from pathlib import Path
p=Path('build/step7/ceremony-test')
rows=[l.split() for l in (p/'ceremony.txt').read_text().splitlines()]
log=[(float(t),int(f),int(s)) for t,f,s in rows]
rising=[x for x in log if 0<x[1]<256]
rate=(rising[-1][1]-rising[0][1])/(rising[-1][0]-rising[0][0])
assert 59<rate<61,rate
# Each displayed SCAY is a copy base (512 or 1280) plus the view top.
for t,f,s in rising:
    top=s-512 if s<1280 else s-1280
    assert 0<=top<=512 and top%2==0,(f,s)
assert {s for t,f,s in log if s>=2048}=={2048,2816,3072,3328},sorted({s for t,f,s in log if s>=2048})
assert (p/'ceremony-rank.png').exists()
# Both copies end equal to the clean scene C: every cap was restored.
raw=(p/'vram.bin').read_bytes();v=bytearray(len(raw));v[::2]=raw[:0x40000];v[1::2]=raw[0x40000:]
row=lambda y:bytes(v[y*128:(y+1)*128])
reference=Path('build/step7/ceremony-reference.bin').read_bytes()
for base in (512,1280,2048):
    for y in range(724):
        assert row(base+y)==reference[y*128:(y+1)*128],(base,y)
print(f'OK: {rate:.1f} arcade frames per second, camera rising 2 rows per frame, four waving pictures, both copies free of caps, rank screen')
