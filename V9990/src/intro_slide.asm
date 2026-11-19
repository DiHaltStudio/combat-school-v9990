; Cartridge introduction, first part (arcade frames 377..490, one per V9990
; frame): both portraits side by side, then NICK's slides up and right to
; its place above JOE's. Called by the region engine (src/mission_prelude.asm,
; PRE_HOOK) once the palette is set and before it copies the screen's
; background, which holds both portraits in their final places (VRAM row
; PRE_BASE_ROW): NICK's is copied from there, JOE's never moves. The path is
; tools/build_intro_anim.py's intro_slide_path (portrait x, y per frame).
;
; RAM: D0E0 command (21 bytes), D0F6 NICK's place on page 0 (x, y) and
; D0F8 on page 1, D0FA hidden page, D0FB path pointer, D0FD frames left.

INTRO_CMD equ 0xd0e0
INTRO_POS equ 0xd0f6
INTRO_PAGE equ 0xd0fa
INTRO_PTR equ 0xd0fb
INTRO_LEFT equ 0xd0fd
INTRO_W equ 124
INTRO_NICK_X equ 131                    ; final place, also in the background
INTRO_JOE_Y equ 110
INTRO_H equ 105
INTRO_JOE_H equ 102

intro_slide:
        ld hl,intro_slide_path
        ld e,(hl)
        inc hl
        ld d,(hl)
        xor a
        call .both
        ld a,1
        call .both
        ld hl,intro_slide_path
        ld (INTRO_PTR),hl
        ld a,INTRO_SLIDE_FRAMES
        ld (INTRO_LEFT),a
        ld a,1
        ld (INTRO_PAGE),a       ; hidden page
.frame:
        ld a,(INTRO_PAGE)
        call intro_erase
        ld hl,(INTRO_PTR)
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld (INTRO_PTR),hl
        ld a,(INTRO_PAGE)
        call intro_nick
        call prelude_vblank
        ld a,(INTRO_PAGE)
        call prelude_show
        ld hl,INTRO_PAGE
        ld a,(hl)
        xor 1
        ld (hl),a
        ld hl,INTRO_LEFT
        dec (hl)
        jr nz,.frame
        ret
; A = page, E, D = NICK's x, y: JOE and NICK there.
.both:
        push af
        push de
        call intro_joe
        pop de
        pop af
        jp intro_nick

; A = page: JOE's portrait from the background.
intro_joe:
        push af
        call intro_template
        ld hl,INTRO_NICK_X
        ld (INTRO_CMD+0),hl
        ld (INTRO_CMD+4),hl
        ld hl,PRE_BASE_ROW+INTRO_JOE_Y
        ld (INTRO_CMD+2),hl
        pop af
        ld h,a
        ld l,INTRO_JOE_Y
        ld (INTRO_CMD+6),hl
        ld hl,INTRO_JOE_H
        ld (INTRO_CMD+10),hl
        ld hl,INTRO_CMD
        jp command

; A = page, E, D = x, y: NICK's portrait there, remembered for the page.
intro_nick:
        push af
        push de
        call intro_template
        pop de
        pop af
        push af
        call intro_place
        ld hl,INTRO_NICK_X
        ld (INTRO_CMD+0),hl
        ld hl,PRE_BASE_ROW
        ld (INTRO_CMD+2),hl
        pop af
        ld l,a
        ld h,0
        add hl,hl
        ld bc,INTRO_POS
        add hl,bc
        ld (hl),e
        inc hl
        ld (hl),d
        ld hl,INTRO_CMD
        jp command

; A = page: black where NICK's portrait was on that page.
intro_erase:
        push af
        call intro_template
        pop af
        ld l,a
        ld h,0
        add hl,hl
        ld bc,INTRO_POS
        add hl,bc
        ld e,(hl)
        inc hl
        ld d,(hl)
        call intro_place
        ld a,0x20               ; LMMV, colour 0
        ld (INTRO_CMD+20),a
        ld hl,INTRO_CMD
        jp command

; A = page, E, D = x, y: destination of the command.
intro_place:
        ld l,e
        ld h,0
        ld (INTRO_CMD+4),hl
        ld l,d
        ld h,a
        ld (INTRO_CMD+6),hl
        ret

intro_template:
        ld hl,intro_slide_command
        ld de,INTRO_CMD
        ld bc,21
        ldir
        ret
intro_slide_command:
        dw 0,0,0,0,INTRO_W,INTRO_H
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
