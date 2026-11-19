from pathlib import Path

p=Path('build/demo/shoot-hud')
def pen(name,x,y):
    phys=(p/f'{name}-vram.bin').read_bytes()
    regs=(p/f'{name}-regs.bin').read_bytes()
    v=bytearray(len(phys));v[::2]=phys[:0x40000];v[1::2]=phys[0x40000:]
    offset=(regs[18]&1)*32768+y*128+x//2
    byte=v[offset]
    return byte>>4 if x%2==0 else byte&15

assert pen('one',8,196)==15 and pen('one',8,199)!=15
assert pen('one',12,196)!=15
assert pen('twentythree',8,196)==15 and pen('twentythree',92,196)==15
assert pen('twentythree',8,199)==15 and pen('twentythree',12,199)!=15
assert pen('fortyfour',8,202)!=15
assert pen('fortyfive',8,202)==15 and pen('fortyfive',12,202)!=15
assert pen('sixtyseven',92,202)==15 and pen('sixtyseven',8,205)==15
assert pen('eightynine',92,205)==15 and pen('eightynine',8,208)==15
for name,y,filled in (('fortyfour',202,0),('fortyfive',202,1),
                       ('sixtyseven',205,1),('eightynine',208,1)):
    background=pen(name,95,y)
    assert all(pen(name,x,y)==background for x in range(8+filled*4,96)), (name,y)
print('OK: hits fill the upper row first, then the lower row')
