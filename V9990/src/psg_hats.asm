; The hats in the air of the graduation (src/psg_music.asm): hats.bin from
; PSG_CALL_HATS, then song 0. Needs src/psg_calls.asm. Keeps every
; register, flag and the interrupt state.
PSG_CALL_HATS equ 0xdc00        ; PSG_HATS of build/psg/driver.inc
PSG_CALL_WAIT equ 0xdf02        ; psg_wait of src/psg_music.asm
psg_hats:
        push af
        push hl
        ld a,i                  ; P/V = interrupts enabled
        push af
        call psg_check
        jr nz,.out
        di
        call PSG_CALL_STOP
        ld a,1
        ld (PSG_CALL_WAIT),a    ; the first event at the next tick
        ld hl,PSG_CALL_HATS
        ld (PSG_CALL_STREAM),hl
.out:
        pop af
        jp po,.keep
        ei
.keep:
        pop hl
        pop af
        ret
