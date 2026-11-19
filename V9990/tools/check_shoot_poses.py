from pathlib import Path

p=Path('build/demo/shoot-poses-test')
poses=Path('build/demo/shoot-poses.bin').read_bytes()
for n,name in enumerate(('left','center','right')):
    phys=(p/f'{name}-vram.bin').read_bytes()
    regs=(p/f'{name}-regs.bin').read_bytes()
    memory=(p/f'{name}-memory.bin').read_bytes()
    assert memory[0xc45a]==n, (name,memory[0xc45a])
    v=bytearray(len(phys));v[::2]=phys[:0x40000];v[1::2]=phys[0x40000:]
    base=(regs[18]&1)*32768
    # Rows 15–59 avoid the targets and the live score overlay.
    for row in range(15,60):
        actual=v[base+(130+row)*128+20:base+(130+row)*128+44]
        assert actual==poses[n*1536+row*24:n*1536+(row+1)*24], (name,row)
print('OK: cursor direction selects and displays the three player poses')
