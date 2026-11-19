#!/usr/bin/env python3
"""make test-psg-music: the PSG registers after each tick of the MSX driver
(build/psg/test/songNN.txt, Spectrum periods) against the Spectrum 128K
captures (../musicPsg/regs/NN_*.txt), with the bits the chip keeps: the
captures hold R1/R3/R5 as 4 bits, while the driver may write a full byte
(some notes read a period high byte from beyond the period table). R7 is
compared without bits 7-6 (10 on the MSX for the joystick ports); R13 is
not compared (it is only written by effects). The first ticks may be offset by the start-up; the
offset that matches best is used and reported."""
import sys
from pathlib import Path

out = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/psg/test')
ref_dir = Path(__file__).resolve().parents[2] / 'musicPsg' / 'regs'
# The chip's register widths (R7 without bits 7-6, which differ on purpose).
MASKS = (0xFF, 0x0F, 0xFF, 0x0F, 0xFF, 0x0F, 0x1F, 0x3F, 0x1F, 0x1F, 0x1F, 0xFF, 0xFF)
bad = 0
for n in range(11):   # 10: the hats (src/psg_hats.asm), then song 0
    ref_file = next(ref_dir.glob(f'{n + (n == 10):02d}_*.txt'))
    ref = [[int(v, 16) for v in l.split()[:13]] for l in ref_file.read_text().splitlines()
           if l.strip() and not l.startswith('#')]
    got = [[int(v, 16) for v in l.split()[:13]] for l in (out / f'song{n:02d}.txt').read_text().splitlines()]
    for row in got:
        assert row[7] & 0xC0 == 0x80, (n, row)
    def norm(r):
        # What the chip keeps: 12-bit tone periods, 5-bit noise and volumes;
        # the period of a silent channel is not heard (after the hats the
        # driver keeps the periods it had, at volume 0).
        r = [v & m for v, m in zip(r, MASKS)]
        for c in range(3):
            if r[8 + c] == 0:
                r[2 * c] = r[2 * c + 1] = 0
        return r
    best = None
    for off in range(-3, 4):
        pairs = [(norm(got[i]), norm(ref[i + off])) for i in range(len(got)) if 0 <= i + off < len(ref)]
        same = sum(a == b for a, b in pairs)
        if best is None or same > best[0]:
            best = (same, off, len(pairs))
    same, off, total = best
    ok = same == total
    bad += not ok
    print(f'{ref_file.stem}: {same}/{total} ticks equal (offset {off})' + ('' if ok else '  <-- differs'))
if bad:
    sys.exit(f'{bad} songs differ')
print('OK: the MSX driver plays the ten songs as the Spectrum, and the hats then song 0 as the arrangement, register by register')
