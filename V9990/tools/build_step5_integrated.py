#!/usr/bin/env python3
"""Relocate the standalone Step 5 into ASCII16 banks 85–90."""
from pathlib import Path
source=Path('src/step5_visual.asm').read_text().replace('"../build/step5/','"')
for bank in range(1,6):
    needle=f'        ld a,{bank}\n        ld (0x7000),a'
    assert source.count(needle)==1,bank
    source=source.replace(needle,f'        ld a,{bank+85}\n        ld (0x7000),a')
needle='''        xor a             ; standalone starts without a preceding bonus
        add a,30'''
assert source.count(needle)==1
source=source.replace(needle,'''        ld a,(0xc736)     ; preceding Step 4 bonus
        add a,30''')
needle='''finish_transition:
        ret'''
assert source.count(needle)==1
source=source.replace(needle,'''finish_transition:
        call psg_wait_song      ; WINNER / LOSER: its music ends first
        di
        ld hl,step5_exit_trampoline
        ld de,0xca80
        ld bc,step5_exit_trampoline_end-step5_exit_trampoline
        ldir
        jp 0xca80
step5_exit_trampoline:
        ld a,95
        ld (0x6000),a
        jp 0x400d
step5_exit_trampoline_end:''')
source = source.replace('"psg_calls.asm"', '"../../src/psg_calls.asm"')  # music calls
Path('build/step5/integrated.asm').write_text(source)
