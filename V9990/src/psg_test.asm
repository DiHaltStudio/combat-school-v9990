; Test cartridge for the PSG music (make test-psg-music): installs the
; driver, then plays the song a test writes to PSG_REQUEST (FEh stops).
        include "../build/psg/driver.inc"
PSG_REQUEST equ 0xc000
        org 0x4000
        db "AB"
        dw start
        ds 12
start:
        di
        ld sp,0xf000
        ld a,0xff
        ld (PSG_REQUEST),a
        ld hl,psg_blob
        call psg_install
.wait:
        halt
        ld a,(PSG_REQUEST)
        cp 0xff
        jr z,.wait
        ld b,a
        ld a,0xff
        ld (PSG_REQUEST),a
        ld a,b
        cp 0xfe
        jr z,.stop
        cp 0xfd
        jr z,.hats
        push af                 ; as the Spectrum capture: a fresh driver
        di
        ld hl,psg_blob
        ld de,PSG_BASE
        ld bc,PSG_SIZE
        ldir
        call PSG_STOP
        pop af
        call PSG_START
        ei
        jr .wait
.stop:
        call PSG_STOP
        jr .wait
.hats:
        call psg_hats
        jr .wait
        include "psg_music.asm"
        include "psg_calls.asm"
        include "psg_hats.asm"
        ds 0x5000-$,0xff
        incbin "../build/psg/hats.bin"  ; 400h before the driver, as in the game
        ds 0x5400-$,0xff
psg_blob:
        incbin "../build/psg/driver.bin"
        ds 0x8000-$,0xff
