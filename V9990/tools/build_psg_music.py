#!/usr/bin/env python3
"""The Spectrum 128K music driver of Combat School (Jas. C. Brooke, Ocean
1987; bank 3 at C000h, dumped by ../musicPsg/tools/capture.sh) made to run
in MSX RAM.

usage: build_psg_music.py BASE [--spectrum-periods] [OUTDIR]

BASE (hex, a multiple of 100h) is where the driver runs: C000h..CEFFh moves
there whole, so every table keeps its place inside its 256-byte page (the
driver steps through them with INC L / INC IXL). Moved:
  - the 16-bit operands of the code, found by following the flow from the
    entry points and the command table (as ../musicPsg/tools/trace_driver.py);
  - the song table (C690h: tempo, then three order lists per song) and the
    order lists (pattern pointers up to 0000h or the next list). The
    patterns themselves hold no addresses.
Changed for the MSX:
  - the AY write loop (C0CDh, ports FFFDh/BFFDh) writes ports A0h/A1h;
  - R7 is stored with bits 7-6 = 10 (port B output, port A input, as the
    BIOS needs them for the joysticks): C0BBh calls an 8-byte routine put in
    the room the old loop leaves;
  - the 82 note periods (C3B2h) are scaled from the Spectrum's AY clock
    (1.7734 MHz) to the MSX PSG (1.7898 MHz), unless --spectrum-periods
    (used by the tests, which compare with the Spectrum captures).
Writes OUTDIR/driver.bin (F00h bytes) and OUTDIR/driver.inc (entry points).
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'musicPsg' / 'tools'))
from z80dis import dis  # noqa: E402

ORG, SIZE = 0xC000, 0xF00
SOURCE = Path(__file__).resolve().parents[2] / 'musicPsg' / 'driver' / 'bank3_pristine.bin'

args = [a for a in sys.argv[1:] if not a.startswith('--')]
base = int(args[0], 16)
out = Path(args[1] if len(args) > 1 else 'build/psg')
spectrum_periods = '--spectrum-periods' in sys.argv
assert base % 0x100 == 0 and base + SIZE <= 0xF380, hex(base)
delta = base - ORG

bank = SOURCE.read_bytes()
drv = bytearray(bank[:SIZE])
rd = lambda a: drv[a - ORG] if ORG <= a < ORG + SIZE else 0
word = lambda a: drv[a - ORG] | drv[a - ORG + 1] << 8
inside = lambda v: ORG <= v < ORG + SIZE

# Code: follow the flow; commands 80h-8Bh jump through C184h by offsets.
entries = [0xC000, 0xC0E5, 0xC13E, 0xC194] + [0xC184 + i + drv[0x184 + i] for i in range(12)]
code = {}
todo = list(entries)
while todo:
    pc = todo.pop()
    while ORG <= pc < ORG + SIZE and pc not in code:
        text, size = dis(rd, pc)
        code[pc] = (text, size)
        m = re.search(r'([0-9A-F]{4})h', text)
        target = int(m.group(1), 16) if m else None
        op = text.split()[0]
        if op in ('jp', 'jr', 'call', 'djnz') and target is not None and '(' not in text:
            todo.append(target)
        if text in ('ret', 'reti', 'retn') or text.startswith('jp (') or \
                (op in ('jp', 'jr') and ',' not in text):
            break
        pc += size
assert max(code) < 0xC35C, 'code past the variables'

# Positions of the 16-bit values that point into the driver.
moves = []
for pc, (text, size) in code.items():
    m = re.search(r'([0-9A-F]{4})h', text)
    if not m or text.split()[0] in ('jr', 'djnz'):
        continue
    value = int(m.group(1), 16)
    if not inside(value):
        continue
    raw = bytes(rd(pc + i) for i in range(size))
    at = raw.rfind(bytes((value & 255, value >> 8)))
    assert at > 0, (hex(pc), text)
    moves.append(pc + at)
starts = sorted({word(0xC690 + 7 * s + 1 + 2 * k) for s in range(10) for k in range(3)})
moves += [0xC690 + 7 * s + 1 + 2 * k for s in range(10) for k in range(3)]
lists = 0
for i, start in enumerate(starts):
    end = starts[i + 1] if i + 1 < len(starts) else 0xC600
    a = start
    while a < end and word(a):
        assert inside(word(a)), hex(a)
        moves.append(a)
        lists += 1
        a += 2
assert lists == 192, lists

# MSX output. The old loop C0CDh-C0E1h (21 bytes) becomes the loop, a jump
# to its end (C0E2h: pop ix, ret) and the R7 routine at C0DAh; C0BBh
# "ld (C3ABh),a" becomes "call C0DAh".
loop = bytes((0x7A, 0xD3, 0xA0, 0x7E, 0x2B, 0xD3, 0xA1, 0x15, 0xF2, 0xCD, 0xC0, 0x18, 0x08))
fix7 = bytes((0xE6, 0x3F, 0xF6, 0x80, 0x32, 0xAB, 0xC3, 0xC9))
assert drv[0xBB:0xBE] == bytes((0x32, 0xAB, 0xC3)) and drv[0xCD:0xD0] == bytes((0x01, 0x3F, 0xFF))
assert len(loop) + len(fix7) == 21
drv[0xCD:0xE2] = loop + fix7
drv[0xBB:0xBE] = bytes((0xCD, 0xDA, 0xC0))
moves = [m for m in moves if not 0xC0CD <= m < 0xC0E2]
moves += [0xC0BB + 1, 0xC0CD + 9, 0xC0DA + 5]

for a in sorted(set(moves)):
    v = word(a) + delta
    drv[a - ORG] = v & 255
    drv[a - ORG + 1] = v >> 8

if not spectrum_periods:
    for i in range(82):
        a = 0x3B2 + 2 * i
        p = drv[a] | drv[a + 1] << 8
        q = min(4095, round(p * 1789773 / 1773400))
        drv[a] = q & 255
        drv[a + 1] = q >> 8

# The hats in the air before the graduation (../musicPsg/10_sombreros_arreglo:
# the arcade's first 11.24 s of song 21h, arranged in the style of song 0),
# not in the driver's format: a list of register writes, played by the
# hook instead of the driver, then song 0 (src/psg_music.asm). Events:
# count of (register, value) pairs, the pairs, ticks until the next event;
# a count of 0 ends. Tone periods scaled to the MSX clock, R7 bits 7-6 = 10.
hats_ticks = [[int(v, 16) for v in l.split()[:13]] for l in
              (SOURCE.parents[1] / 'arrangements' / '10_sombreros_arreglo.txt').read_text().splitlines()
              if l.strip() and not l.startswith('#')]
def msx_regs(r):
    r = list(r)
    for c in range(3):
        period = r[2 * c] | (r[2 * c + 1] & 15) << 8
        if not spectrum_periods:
            period = min(4095, round(period * 1789773 / 1773400))
        r[2 * c], r[2 * c + 1] = period & 255, period >> 8
    r[7] = (r[7] & 0x3F) | 0x80
    return r
hats = bytearray()
shown = [None] * 13
last = None
for tick, row in enumerate(map(msx_regs, hats_ticks)):
    changed = [i for i in range(13) if row[i] != shown[i]]
    if not changed:
        continue
    if last is not None:
        assert 0 < tick - last < 256
        hats.append(tick - last)
    hats.append(len(changed))
    for i in changed:
        hats += bytes((i, row[i]))
    shown = row
    last = tick
hats += bytes((len(hats_ticks) - last, 0))
assert len(hats) <= 0x300, len(hats)

out.mkdir(parents=True, exist_ok=True)
(out / 'hats.bin').write_bytes(hats)
(out / 'driver.bin').write_bytes(drv)
(out / 'driver.inc').write_text(f'''; Generated by tools/build_psg_music.py: the Spectrum music driver in RAM.
PSG_BASE equ 0x{base:04x}
PSG_SIZE equ 0x{SIZE:04x}
PSG_TICK equ 0x{0xC000 + delta:04x}        ; once per 50 Hz tick
PSG_START equ 0x{0xC0E5 + delta:04x}       ; A = song 0-9
PSG_SFX equ 0x{0xC13E + delta:04x}         ; A = effect 0-19
PSG_STOP equ 0x{0xC194 + delta:04x}        ; silence the song
PSG_SONG_ON equ 0x{0xC002 + delta:04x}     ; non-zero while a song plays
PSG_SFX_ON equ 0x{0xC042 + delta:04x}      ; non-zero while an effect plays
; Where tools/build_megarom.py puts driver.bin in the cartridge: the padding
; at the end of bank 25 (the last bank of the picture pack).
PSG_ROM_BANK equ 25
PSG_ROM_ADDR equ 0xb000
PSG_HATS_ROM equ 0xac00        ; hats.bin, {len(hats)} bytes, in the same bank
PSG_HATS equ 0xdc00            ; hats.bin in RAM (DC00h-DEFFh)
PSG_HATS_SIZE equ {len(hats)}
''')
# src/psg_calls.asm holds these addresses literally (no generated include).
calls = (Path(__file__).resolve().parents[1] / 'src' / 'psg_calls.asm').read_text()
if not spectrum_periods:
    for name, value in (('START', 0xC0E5 + delta), ('STOP', 0xC194 + delta), ('SFX', 0xC13E + delta)):
        assert f'PSG_CALL_{name} equ 0x{value:04x}' in calls, f'src/psg_calls.asm: PSG_CALL_{name}'
    assert f'PSG_CALL_HOOK equ 0x{(base - 0x100) >> 8:02x}' in calls, 'src/psg_calls.asm: PSG_CALL_HOOK'
    assert f'PSG_CALL_STREAM equ 0x{base - 0x100:04x}' in calls, 'src/psg_calls.asm: PSG_CALL_STREAM'
    hats_calls = (Path(__file__).resolve().parents[1] / 'src' / 'psg_hats.asm').read_text()
    assert f'PSG_CALL_WAIT equ 0x{base - 0x100 + 2:04x}' in hats_calls, 'src/psg_hats.asm: PSG_CALL_WAIT'
    assert 'PSG_CALL_HATS equ 0xdc00' in hats_calls, 'src/psg_hats.asm: PSG_CALL_HATS'
print(f'driver at {base:04X}h: {len(set(moves))} addresses moved, hats {len(hats)} bytes, '
      f'{"Spectrum" if spectrum_periods else "MSX"} periods')
