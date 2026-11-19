; Power-on screens: native MSX SCREEN 0 credits and V9990 detection (as in
; DONE/Xybots), then the DiHalt
; logo while its PSG music plays, then the B3 cover until a fresh keypress
; (tools/build_boot_logo.py). Bank 27 at page
; 2: init (src/demo_b1.asm) maps it and calls 0x8000 once, at power-on, with
; interrupts off and before the music driver is installed. The BIOS is at
; page 0. Leaves the V9990 reset, its display off, and the PSG silent.
;
; Tests set BOOT_SKIP (D0FCh) to A5h to bypass the power-on screens.

BOOT_SKIP equ 0xd0fc
BOOT_PTR equ 0xd0f4             ; the music's next command (0: ended)
CHPUT equ 0x00a2
INITXT equ 0x006c
CHGCLR equ 0x0062
ENASCR equ 0x0044
CLS equ 0x00c3
CLIKSW equ 0xf3db
LINL40 equ 0xf3ae
FORCLR equ 0xf3e9
BAKCLR equ 0xf3ea
BDRCLR equ 0xf3eb

        org 0x8000
boot_screens:
        xor a
        out (0x6f),a            ; V7040: no superimpose
        ld b,1                  ; about 0.5 s for the V7040 to settle
        call boot_pause
        call boot_banner
        call boot_reset
        call boot_probe
        ld hl,boot_missing
        jr nc,.missing
        ld hl,boot_found
        call boot_print
        di
        ld b,4                  ; time to read the MSX screen before takeover
        call boot_pause
        ld a,(BOOT_SKIP)
        cp 0xa5
        jr z,.done
        call boot_logo
        call boot_opening
.done:
        call boot_reset
        ret
.missing:
        call boot_print
        di
.stop:
        jr .stop

boot_banner:
        ld a,40
        ld (LINL40),a
        ld a,15                 ; white on dark blue
        ld (FORCLR),a
        ld a,4
        ld (BAKCLR),a
        ld (BDRCLR),a
        call INITXT
        call CHGCLR
        xor a
        call CLS
        call ENASCR
        di
        xor a
        ld (CLIKSW),a
        ld hl,boot_credits
        jp boot_print

; B = units of about 0.45 s (none while BOOT_SKIP is set).
boot_pause:
        ld a,(BOOT_SKIP)
        cp 0xa5
        ret z
.unit:
        ld de,0
.loop:
        dec de
        ld a,d
        or e
        jr nz,.loop
        djnz .unit
        ret

boot_print:
        ld a,(hl)
        or a
        ret z
        push hl
        call CHPUT
        pop hl
        inc hl
        jr boot_print

; The V9990 reset: every register 0, display off.
boot_reset:
        ld a,2
        out (0x67),a
        xor a
        out (0x67),a
        ret

; CF when a V9990 answers: two bytes written to its VRAM come back.
boot_probe:
        ld a,8
        out (0x64),a
        ld a,2                  ; 512 KiB addressing, display off
        out (0x63),a
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        out (0x63),a
        ld a,0xa5
        out (0x60),a
        ld a,0x5a
        out (0x60),a
        ld a,3
        out (0x64),a
        xor a
        out (0x63),a
        out (0x63),a
        out (0x63),a
        in a,(0x60)
        cp 0xa5
        jr nz,.no
        in a,(0x60)
        cp 0x5a
        jr nz,.no
        scf
        ret
.no:
        or a
        ret

; The logo in B1 with BD8 colour (one byte a pixel), for as long as its music.
boot_logo:
        ld hl,boot_b1
.reg:
        ld a,(hl)
        inc hl
        cp 0xff
        jr z,.registers_set
        out (0x64),a
        ld a,(hl)
        inc hl
        out (0x63),a
        jr .reg
.registers_set:
        call boot_frame         ; palette 0 (the border) white
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ld a,31
        out (0x61),a
        out (0x61),a
        out (0x61),a
        xor a                   ; VRAM write pointer 0
        out (0x64),a
        out (0x63),a
        out (0x63),a
        out (0x63),a
        ld hl,boot_logo_rle
.run:
        ld b,(hl)
        inc b
        dec b
        jr z,.uploaded
        inc hl
        ld a,(hl)
        inc hl
.byte:
        out (0x60),a
        djnz .byte
        jr .run
.uploaded:
        ld a,8
        out (0x64),a
        ld a,0x82               ; display on
        out (0x63),a
        ld hl,boot_music
        ld (BOOT_PTR),hl
.music:
        call boot_frame
        call boot_tick
        ld a,(BOOT_PTR+1)
        or a
        jr nz,.music
        ld a,8
        out (0x64),a
        ld a,2                  ; display off
        out (0x63),a
        ret

; Waits for the start of the V9990's vertical blank (50 Hz: PAL).
boot_frame:
        in a,(0x65)
        and 0x40
        jr nz,boot_frame
.blank:
        in a,(0x65)
        and 0x40
        jr z,.blank
        ret

; One frame of the music: A0 rr dd writes until 63 (the frame ends) or 66
; (the end: volumes 0, BOOT_PTR 0).
boot_tick:
        ld hl,(BOOT_PTR)
.command:
        ld a,(hl)
        inc hl
        cp 0xa0
        jr nz,.not_write
        ld a,(hl)
        inc hl
        out (0xa0),a
        cp 7
        ld a,(hl)
        inc hl
        jr nz,.write
        and 0x3f                ; R7: port A in, port B out
        or 0x80
.write:
        out (0xa1),a
        jr .command
.not_write:
        cp 0x63
        jr z,.frame_end
        ld hl,0
        ld a,8
.mute:
        out (0xa0),a
        push af
        xor a
        out (0xa1),a
        pop af
        inc a
        cp 11
        jr nz,.mute
.frame_end:
        ld (BOOT_PTR),hl
        ret

; Cover after DiHalt, in B3/BD8 at 512x424 interlaced as in Xybots.
; Interrupts stay off. Code runs in bank 27 on page 2, so page 1 can
; stream the image banks and must be restored to bank 0 before returning.
boot_opening:
        ld a,6
        out (0x64),a
        ld a,0x96               ; B3, 512 pixels per line, 8 bpp
        out (0x63),a
        ld a,0x0e               ; PAL, interlace, even/odd fields
        out (0x63),a
        call boot_frame
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        out (0x61),a            ; backdrop entry 0 is black
        out (0x61),a
        out (0x61),a
        out (0x64),a            ; VRAM write pointer 0
        out (0x63),a
        out (0x63),a
        out (0x63),a
        ld ix,opening_banks
.bank:
        ld a,(ix+0)
        or a
        jr z,.ready
        ld (0x6000),a
        ld d,(ix+1)
        inc ix
        inc ix
        ld hl,0x4000
        ld c,0x60
.row:
        call .margin
        ld b,0
        otir                    ; 256 bytes from the picture
        ld b,OPENING_WIDTH-256
        otir                    ; rest of the picture row
        call .margin
        dec d
        jr nz,.row
        jr .bank
.margin:
        ld b,(512-OPENING_WIDTH)/2
        xor a
.pixel:
        out (c),a
        djnz .pixel
        ret
.ready:
        ld (0x6000),a           ; page 1: restore the bank that called us
        call boot_frame
        ld a,0xc8              ; R#8, no auto-increment during read-modify-write
        out (0x64),a
        in a,(0x63)
        or 0x80
        out (0x63),a
.release_old:
        call boot_frame
        call boot_key
        jr nz,.release_old
.wait_key:
        call boot_frame
        call boot_key
        jr z,.wait_key
.release_new:
        call boot_frame
        call boot_key
        jr nz,.release_new     ; the same key must not start the game too
        ld a,0xc8
        out (0x64),a
        in a,(0x63)
        and 0x7f
        out (0x63),a
        ret

; Z if all keyboard rows are released. Restore the PPI selector.
boot_key:
        in a,(0xaa)
        push af
        and 0xf0
        ld c,a
        ld b,11
.row:
        ld a,c
        out (0xaa),a
        in a,(0xa9)
        inc a
        jr nz,.pressed
        inc c
        djnz .row
        pop af
        out (0xaa),a
        xor a
        ret
.pressed:
        pop af
        out (0xaa),a
        ld a,1
        or a
        ret

        include "../build/boot/opening.inc"
boot_b1:
        db 6,0x82               ; B1, 256-pixel image space, 8 bpp
        db 7,0x08               ; PAL
        db 8,0x02               ; display off
        db 9,0
        db 13,0x40              ; BD8
        db 15,0                 ; border: palette 0
        db 0xff
boot_credits:
        db "COMBAT SCHOOL",13,10,"KONAMI 1987",13,10,"DIHALT 2026",13,10,13,10,0
boot_found:   db "V9990 found!",0
boot_missing: db "V9990 NOT found!",0
boot_music:
        incbin "../build/boot/logo-music.bin"
boot_logo_rle:
        incbin "../build/boot/logo.rle"
boot_end:
        assert boot_end <= 0xc000
