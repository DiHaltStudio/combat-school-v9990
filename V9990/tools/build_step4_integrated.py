#!/usr/bin/env python3
"""Relocate the standalone Step 4 to ASCII16 banks 77–82."""
from pathlib import Path
source=Path('src/step4_visual.asm').read_text().replace('"../build/step4/', '"')
needle='''        ; Standalone test ROM only (tools/build_step4_integrated.py removes
        ; it): the game score starts at zero.
        xor a
        ld (0xc75c),a
        ld (0xc75d),a
        ld (0xc75e),a
'''
assert source.count(needle)==1
source=source.replace(needle,'')
needle='        ld (0xc883),a\n        ld hl,0xca00'
assert source.count(needle)==1
source=source.replace(needle,'        ld (0xc883),a\n        ld (0xca24),a\n        ld hl,0xca00')
needle='result_input:\n        xor a'
assert source.count(needle)==1
source=source.replace(needle,'''result_input:
        ld a,(0xc80c)
        cp 1
        jr nz,.failure_input
        ld a,(0xca24)
        or a
        jr nz,.result_wait
        inc a
        ld (0xca24),a
        ld hl,(0xfc9e)
        ld (0xca25),hl
.result_wait:
        ld hl,(0xfc9e)
        ld de,(0xca25)
        or a
        sbc hl,de
        ld a,(0xc81c)
        ld e,a
        add a,a
        add a,e
        ld e,a
        ld d,0
        or a
        sbc hl,de
        ret c
        di
        ld hl,step4_result_trampoline
        ld de,0xca80
        ld bc,step4_result_trampoline_end-step4_result_trampoline
        ldir
        jp 0xca80
.failure_input:
        ; 48-51 hits of 52: 10-7 chin-ups (arcade 0xd49c), once per game.
        ld a,(0xc809)
        ld c,a
        ld a,52
        sub c
        jr c,.no_penalty
        jr z,.no_penalty
        cp 5
        jr nc,.no_penalty
        add a,6
        jr .penalty
.no_penalty:
        xor a
.penalty:
        ld b,4
        call 0xf210
        ret c
        xor a''')
needle='clock:\n'
assert source.count(needle)==1
source=source.replace(needle,'''step4_result_trampoline:
        ld a,95
        ld (0x6000),a
        jp 0x400a
step4_result_trampoline_end:
clock:
''')
for n in (1,2,3):
 needle=f'        ld a,{n}\n        ld (0x7000),a'
 assert source.count(needle)==1
 source=source.replace(needle,f'        ld a,{n+77}\n        ld (0x7000),a')
needle='        ld a,4\n        ld (0xc8e8),a'
assert source.count(needle)==1
source=source.replace(needle,'        ld a,81\n        ld (0xc8e8),a')
needle='        ld a,39\n        ld (0xc806),a'
assert source.count(needle)==1
source=source.replace(needle,'''        ld a,(0xc736)
        add a,34
        ld (0xc806),a
        ld a,11
        ld (0xc418),a''')
source = source.replace('"psg_calls.asm"', '"../../src/psg_calls.asm"')  # music calls
Path('build/step4/integrated.asm').write_text(source)
