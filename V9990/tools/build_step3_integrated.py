#!/usr/bin/env python3
"""Generate the bank-relocated Step 3 assembly for the 2 MiB cartridge.

The standalone source remains the canonical implementation. Its ROM bank 0
is mapped at cartridge bank 95; every data bank reference is relative to it.
"""
from pathlib import Path
source=Path('src/step3_visual.asm').read_text()
source=source.replace('\"../build/step3/', '\"').replace('\"step3_camera.asm\"', '\"../../src/step3_camera.asm\"').replace('\"psg_calls.asm\"', '\"../../src/psg_calls.asm\"')
needle='        ld (0x7000),a'
assert source.count(needle)==10
source=source.replace(needle,'        add a,95\n'+needle)
needle='''        ld a,45
        ld (0xc731),a'''
assert source.count(needle)==1
source=source.replace(needle,'''        ; Shooting bonus carries forward as extra seconds.
        ld a,(0xc43f)
        add a,45
        ld (0xc731),a
        ; Retain the two existing bonus-point totals for later score work.
        ld hl,(0xc414)
        ld de,(0xc440)
        add hl,de
        ld (0xc75c),hl
        ld a,0
        adc a,0
        ld (0xc75e),a
        xor a
        ld (0xc760),a
        ld a,7
        ld (0xc418),a''')
needle='result_input:\n        ld a,(0xc72f)'
assert source.count(needle)==1
source=source.replace(needle,"""result_input:
        ld a,(0xc735)
        or a
        jr nz,.original_failure_input
        ld a,(0xc72f)
        or a
        ret z
        jp transition_poll
.original_failure_input:
        ; Time up close to the goal: the penalty, once per game. Arcade
        ; (0xc4ea, 0xcdc4): up to 256 of its 3856 pixels, 5..8 chin-ups;
        ; scaled to the 3328 of this course (src/penalty.asm).
        ld hl,(0xc700)
        ex de,hl
        ld hl,3328
        or a
        sbc hl,de
        jr nc,.penalty_distance
        ld hl,0
.penalty_distance:
        ld de,step3_penalty_bands
.penalty_band:
        ld a,(de)
        inc de
        ld c,a
        ld a,(de)
        inc de
        ld b,a
        ld a,(de)
        inc de
        or a
        sbc hl,bc
        add hl,bc
        jr nc,.penalty_band
        ld b,3
        call 0xf210
        ret c
        ld a,(0xc72f)""")
needle='''        ; Standalone test ROM only (tools/build_step3_integrated.py removes
        ; it): the game score starts at zero.
        xor a
        ld (0xc75c),a
        ld (0xc75d),a
        ld (0xc75e),a
'''
assert source.count(needle)==1
source=source.replace(needle,'')
needle='        ds 6,0\ninit:'
assert source.count(needle)==1
source=source.replace(needle,'        jp step4_transition\n        jp step5_transition\ninit:')
needle='        include "../../src/step3_camera.asm"'
assert source.count(needle)==1
source=source.replace(needle,'''step3_penalty_bands:
        dw 55
        db 5
        dw 110
        db 6
        dw 180
        db 7
        dw 222
        db 8
        dw 0xffff
        db 0
        include "../../src/step3_camera.asm"''')
needle='        include "../../src/step3_camera.asm"'
assert source.count(needle)==1
source=source.replace(needle,'        include "../../src/step3_transition.asm"\n        include "../demo/image-table.inc"\n'+needle)
Path('build/step3/step3_integrated.asm').write_text(source)
