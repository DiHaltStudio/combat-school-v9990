#!/usr/bin/env python3
"""Relocate the Step 7 prototype into the free ASCII16 MegaROM banks."""
import re
from pathlib import Path

p = Path('build/step7')
source = Path('src/step7_visual.asm').read_text().replace('"../build/step7/', '"')
# Pack the three RLE streams into two consecutive banks. Each is aligned so
# that a bank boundary never splits a count/value pair.
packed = bytearray()
for original, filename in enumerate(('field-rle-bank.bin', 'atlas0-rle-bank.bin', 'atlas1-rle-bank.bin'), 1):
    data = (p/filename).read_bytes()
    end = 0
    while data[end]:
        end += 2
    if len(packed) & 1:
        packed.append(255)
    bank, offset = 91 + len(packed)//0x4000, len(packed)%0x4000
    packed.extend(data[:end+1])
    needle = f'        ld a,{original}\n        ld (0x7000),a\n        ld hl,0x8000'
    assert source.count(needle) == 1, original
    source = source.replace(needle, f'        ld a,{bank}\n        ld (0x7000),a\n        ld (0xc839),a\n        ld hl,0x{0x8000+offset:04x}')
assert len(packed) <= 2*0x4000
packed.extend(bytes([255])*(2*0x4000-len(packed)))
(p/'combat-packed.bin').write_bytes(packed)
needle = 'upload_rle:\n        ld b,(hl)'
assert source.count(needle) == 1
source = source.replace(needle, '''upload_rle:
        ld a,h
        cp 0xc0
        jr nz,.read_pair
        ld a,(0xc839)
        inc a
        ld (0xc839),a
        ld (0x7000),a
        ld hl,0x8000
.read_pair:
        ld b,(hl)''')
needle = '''        incbin "field-rle-bank.bin"
        incbin "atlas0-rle-bank.bin"
        incbin "atlas1-rle-bank.bin"'''
assert source.count(needle) == 1
source = source.replace(needle, '        incbin "combat-packed.bin"')
needle = '''        ld (0xc75e),a          ; standalone starts with zero accumulated score
        ld hl,0
        ld (0xc75c),hl'''
assert source.count(needle) == 1
source = source.replace(needle, '''        ld a,21                ; integrated Step 7; preserve the game score
        ld (0xc418),a''')
source = source.replace('"ending.inc"', '"ending-integrated.inc"')
# Includes resolve from build/step7, where this file is written.
source = source.replace('"step7_ceremony.asm"', '"../../src/step7_ceremony.asm"')
ending = (p/'ending.inc').read_text()
# Standalone banks 4.. (ending.bin) and atlas2 after them become 67.. here.
ending_banks = int(re.search(r'ENDING_BANKS equ (\d+)', ending).group(1))
for bank in range(3 + ending_banks, 3, -1):
    ending = ending.replace(f'        db {bank} ;', f'        db {bank+63} ;')
ending = re.sub(r'(ATLAS2_BANK|CEREMONY_CAPS_BANK) equ (\d+)', lambda m: f'{m.group(1)} equ {int(m.group(2))+63}', ending)
(p/'ending-integrated.inc').write_text(ending)
needle = '        ld a,ATLAS2_BANK\n        ld (0x7000),a\n        ld hl,0x8000'
assert source.count(needle) == 1
source = source.replace(needle, '        ld a,ATLAS2_BANK\n        ld (0x7000),a\n        ld (0xc839),a\n        ld hl,0x8000')
# The third atlas (moves added on 16-nov) is not among the banks from 67:
# tools/build_megarom.py puts it in the free bank 56.
needle = '        incbin "atlas3-rle-bank.bin"\n'
assert source.count(needle) == 1
source = source.replace(needle, '')
needle = 'ATLAS3_BANK equ ATLAS2_BANK+1'
assert source.count(needle) == 1
source = source.replace(needle, 'ATLAS3_BANK equ 56')
needle = '        ld a,ATLAS3_BANK\n        ld (0x7000),a\n        ld hl,0x8000'
assert source.count(needle) == 1
source = source.replace(needle, '        ld a,ATLAS3_BANK\n        ld (0x7000),a\n        ld (0xc839),a\n        ld hl,0x8000')
# Arcade clock: 1:00.0 plus the Step 6 bonus seconds.
needle = '        ld a,60                ; arcade clock 1:00.0 (+ Step 6 bonus)'
assert source.count(needle) == 1
source = source.replace(needle, '        ld a,(0xc43f)          ; Step 6 bonus seconds\n        add a,60')
# Lost against the instructor: GAME OVER and the title (src/demo_b1.asm).
needle = 'result_input:\n        xor a\n'
assert source.count(needle) == 1
source = source.replace(needle, 'result_input:\n        xor a\n        ld b,7\n        call 0xf210\n        ret c\n        xor a\n')
# Won: rank screen, the map again (arcade), then the final mission
# (build/mission/integrated.rom, banks 34.., entry 0x4010) through RAM.
needle = '.rank_wait:\n        halt\n        call result_input\n        jr .rank_wait\n'
assert source.count(needle) == 1
source = source.replace(needle, '''        ld a,5
        call ending_seconds
        xor a
        call ending_show
        ld a,3
        call ending_seconds
        di
        ld hl,mission_trampoline
        ld de,0xca80
        ld bc,mission_trampoline_end-mission_trampoline
        ldir
        jp 0xca80
mission_trampoline:
        ld a,34
        ld (0x6000),a
        jp 0x4010
mission_trampoline_end:
''')
source = source.replace('"psg_calls.asm"', '"../../src/psg_calls.asm"')  # music calls
source = source.replace('"psg_hats.asm"', '"../../src/psg_hats.asm"')
(p/'integrated.asm').write_text(source)
