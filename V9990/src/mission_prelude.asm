; The two arcade screens before the mission (tools/extract_mission_prelude.py):
; "ATTENTION! ... SAVE THE HOSTAGES!" typed on black with two saluting
; soldiers, then the mansion with explosions, the windows' fire (palette
; entry 15 cycling) and the player walking to the door. Frame by frame as
; in the arcade, one frame per V9990 frame (60 Hz).
;
; VRAM rows: pages 0 and 256 (shown alternately), clean background 512,
; picture atlas 768. In each frame every region shows the background or
; one transparent picture; when its state on the hidden page differs, the
; region is restored from the background and the picture drawn.
;
; RAM D000..D0B4: D000 hidden page, D001 frames left (word), D003 screen
; (word), D005 colour cycle run (word), D007 frames left in it, D008 colour
; to write (flag + R, G, B); D010 ten regions of 12 bytes: run (word),
; frames left in it, picture, dx, dy, then picture, dx, dy shown on page 0
; and on page 1; D0A0 one V9990 command; D0B6 bank mapped back after
; each upload (the ending runs from page 2).

PRE_PAGE equ 0xd000
PRE_LEFT equ 0xd001
PRE_SCREEN equ 0xd003
PRE_CYCLE equ 0xd005
PRE_CYCLE_LEFT equ 0xd007
PRE_COLOUR equ 0xd008
PRE_REGIONS equ 0xd010
PRE_CMD equ 0xd0a0
PRE_HOME equ 0xd0b6             ; bank to map at page 2 after an upload (0: none)
PRE_HOOK equ 0xd0ba             ; routine called before the background (0: none)
PRE_BASE_ROW equ 512
PRE_ATLAS_ROW equ 768

mission_prelude:
        ld a,(0xd0ff)
        cp 0xa5
        ret z                   ; tests: tools/skip_mission_prelude.tcl
        ld a,1                  ; ATTENTION: the PLAYER READY music (Spectrum)
        call psg_play
        xor a
        ld (PRE_HOME),a
        ld h,a
        ld l,a
        ld (PRE_HOOK),hl
        ld hl,prelude_attention
        call prelude_screen
        ld a,ARC_MANSION        ; the mansion: the arcade's 2Eh (src/psg_arcade.asm);
        call psg_arcade         ; the uploads below map their own banks
        ld hl,prelude_mansion
        ; fall through

; HL = screen (see tools/mission_prelude_data.py).
prelude_screen:
        ld (PRE_SCREEN),hl
        ld de,0
        ld (PRE_LEFT),de        ; 0 until the screen is displayed
        push hl
        pop iy
        ; Black on both pages while the pictures load.
        ld hl,prelude_clear
        call prelude_copy_template
        ld hl,PRE_CMD
        call raw_command
        xor a
        call prelude_show
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld a,(iy+11)
        ld l,(iy+12)
        ld h,(iy+13)
        ld de,PRE_BASE_ROW
        call prelude_upload
        ld a,(iy+14)
        ld l,(iy+15)
        ld h,(iy+16)
        ld de,PRE_ATLAS_ROW
        call prelude_upload
        ld b,(iy+0)
        call prelude_wait
        ; Palette, then the background on both pages.
        call prelude_vblank
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ld l,(iy+5)
        ld h,(iy+6)
        ld bc,0x3061
        otir
        ; PRE_HOOK, when not 0: frames drawn before the background (the
        ; cartridge introduction slides a portrait in, src/demo_b1.asm).
        ld hl,(PRE_HOOK)
        ld a,h
        or l
        push iy
        call nz,prelude_hook
        pop iy
        ld hl,0
        call prelude_background
        ld hl,256
        call prelude_background
        ; Regions start on their first run; both pages show the background.
        ld b,(iy+4)
        ld ix,PRE_REGIONS
        push iy
        ld de,17
        add iy,de
.init:
        ld l,(iy+4)
        ld h,(iy+5)
        call prelude_load_run
        ld a,255
        ld (ix+6),a
        ld (ix+9),a
        ld de,12
        add ix,de
        ld de,6
        add iy,de
        djnz .init
        pop iy
        ld l,(iy+9)
        ld h,(iy+10)
        ld (PRE_CYCLE),hl
        ld a,h
        or l
        jr z,.cycle_ready       ; no colour cycle: 0 frames left
        ld a,1                  ; the first advance loads the first colour
.cycle_ready:
        ld (PRE_CYCLE_LEFT),a
        xor a
        ld (PRE_COLOUR),a
        inc a
        ld (PRE_PAGE),a
        ld l,(iy+1)
        ld h,(iy+2)
        ld (PRE_LEFT),hl
.frame:
        call prelude_draw
        call prelude_advance
        call prelude_vblank
        ld a,(PRE_COLOUR)
        or a
        jr z,.colour_done
        ld a,14
        out (0x64),a
        ld a,15*4               ; palette entry 15
        out (0x63),a
        ld hl,PRE_COLOUR+1
        ld bc,0x0361
        otir
        xor a
        ld (PRE_COLOUR),a
.colour_done:
        ld a,(PRE_PAGE)
        call prelude_show
        ld hl,PRE_PAGE
        ld a,(hl)
        xor 1
        ld (hl),a
        ld hl,(PRE_LEFT)
        dec hl
        ld (PRE_LEFT),hl
        ld a,h
        or l
        jr nz,.frame
        ; Black frames after the screen.
        ld iy,(PRE_SCREEN)
        call prelude_vblank
        call display_off        ; off from the next frame on
        ld b,(iy+3)
        jp prelude_wait

; IX = region state, HL = run: copies the run (picture, dx, dy, frames).
prelude_load_run:
        ld (ix+0),l
        ld (ix+1),h
        ld a,(hl)
        ld (ix+3),a
        inc hl
        ld a,(hl)
        ld (ix+4),a
        inc hl
        ld a,(hl)
        ld (ix+5),a
        inc hl
        ld a,(hl)
        ld (ix+2),a
        ret

; Next frame of every region and of the colour cycle.
prelude_advance:
        ld iy,(PRE_SCREEN)
        ld b,(iy+4)
        ld ix,PRE_REGIONS
.region:
        dec (ix+2)
        jr nz,.next
        ld l,(ix+0)
        ld h,(ix+1)
        ld de,4
        add hl,de
        call prelude_load_run
.next:
        ld de,12
        add ix,de
        djnz .region
        ld hl,PRE_CYCLE_LEFT
        ld a,(hl)
        or a
        ret z
        dec (hl)
        ret nz
        ld hl,(PRE_CYCLE)
        ld de,PRE_COLOUR+1
        ld bc,3
        ldir
        ld a,(hl)
        inc hl
        ld (PRE_CYCLE),hl
        ld (PRE_CYCLE_LEFT),a
        ld a,1
        ld (PRE_COLOUR),a
        ret

; Brings every region of the hidden page to its current state.
prelude_draw:
        ld iy,(PRE_SCREEN)
        ld b,(iy+4)
        ld de,17
        add iy,de
        ld ix,PRE_REGIONS
.region:
        push bc
        ld a,(PRE_PAGE)
        or a
        ld bc,6                 ; shown state on page 0 at +6, page 1 at +9
        jr z,.shown
        ld c,9
.shown:
        push ix
        pop hl
        add hl,bc
        ld a,(ix+3)
        cp (hl)
        jr nz,.redraw
        ld a,(ix+4)
        inc hl
        cp (hl)
        jr nz,.redraw_back
        ld a,(ix+5)
        inc hl
        cp (hl)
        jp z,.next
        dec hl
.redraw_back:
        dec hl
.redraw:
        ld a,(ix+3)
        ld (hl),a
        inc hl
        ld a,(ix+4)
        ld (hl),a
        inc hl
        ld a,(ix+5)
        ld (hl),a
        ; Restore the region from the clean background.
        ld hl,prelude_restore
        call prelude_copy_template
        ld a,(iy+0)
        ld (PRE_CMD+0),a        ; SX
        ld (PRE_CMD+4),a        ; DX
        ld l,(iy+1)
        ld h,0
        push hl
        ld de,PRE_BASE_ROW
        add hl,de
        ld (PRE_CMD+2),hl       ; SY
        pop hl
        call prelude_page_row
        ld (PRE_CMD+6),hl       ; DY
        ld a,(iy+2)
        ld (PRE_CMD+8),a
        ld a,(iy+3)
        ld (PRE_CMD+10),a
        ld hl,PRE_CMD
        call raw_command
        ld a,(ix+3)
        cp 255
        jp z,.next
        ; Transparent picture at the region origin plus (dx, dy).
        ld hl,prelude_picture
        call prelude_copy_template
        push iy
        ld iy,(PRE_SCREEN)
        ld l,(iy+7)
        ld h,(iy+8)
        pop iy
        ld a,(ix+3)
        ld e,a
        ld d,0
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        ld a,(hl)
        ld (PRE_CMD+0),a        ; SX
        inc hl
        ld a,(hl)
        inc hl
        push hl
        ld l,a
        ld h,0
        ld de,PRE_ATLAS_ROW
        add hl,de
        ld (PRE_CMD+2),hl       ; SY
        pop hl
        ld a,(hl)
        ld (PRE_CMD+8),a        ; NX
        inc hl
        ld a,(hl)
        ld (PRE_CMD+10),a       ; NY
        ld a,(iy+0)
        add a,(ix+4)
        ld (PRE_CMD+4),a        ; DX
        ld a,(iy+1)
        add a,(ix+5)
        ld l,a
        ld h,0
        call prelude_page_row
        ld (PRE_CMD+6),hl       ; DY
        ld hl,PRE_CMD
        call raw_command
.next:
        ld de,12
        add ix,de
        ld de,6
        add iy,de
        pop bc
        dec b
        jp nz,.region
        ret

; HL = row on the screen -> row on the hidden page.
prelude_page_row:
        ld a,(PRE_PAGE)
        add a,h
        ld h,a
        ret

prelude_copy_template:
        ld de,PRE_CMD
        ld bc,21
        ldir
        ret

; HL = page row: copies the clean background there.
prelude_background:
        push hl
        ld hl,prelude_restore
        call prelude_copy_template
        pop hl
        ld (PRE_CMD+6),hl
        ld hl,PRE_BASE_ROW
        ld (PRE_CMD+2),hl
        xor a
        ld (PRE_CMD+0),a
        ld (PRE_CMD+4),a
        ld (PRE_CMD+9),a
        inc a
        ld (PRE_CMD+9),a        ; NX = 256
        xor a
        ld (PRE_CMD+8),a
        ld a,212
        ld (PRE_CMD+10),a
        ld hl,PRE_CMD
        jp raw_command

; A = bank, HL = RLE stream, DE = VRAM row.
prelude_upload:
        ld (0x7000),a
        ld (0xc839),a
        xor a
        out (0x64),a
        ld a,e
        rrca
        and 0x80
        out (0x63),a
        ld a,d
        rra
        ld a,e
        rra
        out (0x63),a
        ld a,d
        srl a
        out (0x63),a
        call upload_pack
        ld a,(PRE_HOME)
        or a
        ret z
        ld (0x7000),a           ; the ending's bank (src/mission_ending.asm)
        ret

; HL = stream (tools/build_image_pack.py format) in the bank at (0xc839):
; 1..127 literal bytes, 129..255 the next byte (control - 128) times, 128
; the next bank, 0 the end.
upload_pack:
        ld a,(hl)
        inc hl
        or a
        ret z
        cp 128
        jr c,.literal
        jr z,.bank
        sub 128
        ld b,a
        ld a,(hl)
        inc hl
.run:
        out (0x60),a
        djnz .run
        jr upload_pack
.literal:
        ld b,a
        ld c,0x60
        otir
        jr upload_pack
.bank:
        ld a,(0xc839)
        inc a
        ld (0xc839),a
        ld (0x7000),a
        ld hl,0x8000
        jr upload_pack

prelude_hook:
        jp (hl)

; A = page (0/1): SCAY = 256 * page.
prelude_show:
        ld b,a
        ld a,17
        out (0x64),a
        xor a
        out (0x63),a
        ld a,b
        out (0x63),a
        ret

; B = frames to wait.
prelude_wait:
        ld a,b
        or a
        ret z
.frame:
        push bc
        call prelude_vblank
        pop bc
        djnz .frame
        ret

prelude_vblank:
.end:
        in a,(0x65)
        bit 6,a
        jr nz,.end
.start:
        in a,(0x65)
        bit 6,a
        jr z,.start
        ret

prelude_clear:
        dw 0,0,0,0,256,512
        db 0,0x0c,0xff,0xff,0,0,0,0,0x20
prelude_restore:
        dw 0,0,0,0,0,0
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
prelude_picture:
        dw 0,0,0,0,0,0
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
