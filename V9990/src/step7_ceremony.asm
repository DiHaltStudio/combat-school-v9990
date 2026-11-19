; Graduation ceremony as in the arcade (tools/extract_step7_ceremony.py):
; the soldiers raise their arms, the camera rises 512 pixels at 2 pixels per
; frame from the stage to the flag while eight caps fly up, and the flag
; waves with four pictures of 10 frames each.
;
; VRAM rows (B1, 256 pixels wide): scene copies A 512..1235 and B
; 1280..2003 (displayed alternately with the scroll register, SCAY), clean
; scene C 2048..2771 (its first 212 rows are waving picture 0), waving
; pictures 1..3 at 2816, 3072 and 3328, cap pictures at 3584 (x = 16 *
; picture). Caps are drawn on the hidden copy after restoring the previous
; ones from C, then SCAY shows that copy at vertical blank.
;
; RAM C900..C9DF: C900 frame (word), C902 hidden copy, C903 next track
; header (word), C906 view top (word); C910 12 cap
; slots of 8 bytes (data word, steps left word, x, y, picture, active);
; C970 / C9A4 caps drawn on copy A / B (count, then x, scene y word,
; picture); C9E0 one V9990 command of 21 bytes.

CER_FRAME equ 0xc900
CER_HIDDEN equ 0xc902
CER_NEXT equ 0xc903
CER_TOP equ 0xc906
CER_SLOTS equ 0xc910
CER_SLOT_COUNT equ 12
CER_DRAWN_A equ 0xc970
CER_DRAWN_B equ 0xc9a4
CER_CMD equ 0xc9e0
CER_A equ 512
CER_B equ 1280
CER_C equ 2048
CER_CAPS_Y equ 3584
MSX_LOGO_PEN equ 12             ; a seldom-used shade in the shared palette

ceremony_load:
        ld a,2
        ld hl,CER_C
        call ceremony_upload
        ld a,3
        ld hl,2816
        call ceremony_upload
        ld a,4
        ld hl,3072
        call ceremony_upload
        ld a,5
        ld hl,3328
        call ceremony_upload
        ld a,6
        ld hl,CER_CAPS_Y
        call ceremony_upload
        ld a,(0xf207)
        cp 1
        call z,ceremony_msx_flags
        ld hl,CER_A
        call .copy
        ld hl,CER_B
.copy:
        push hl
        ld hl,ceremony_scene_template
        ld de,CER_CMD
        ld bc,21
        ldir
        pop hl
        ld (CER_CMD+6),hl
        ld hl,CER_CMD
        jp command

; Apply the warped flag print to the four wave pages during loading.
; Each row holds Y, first X, and runs of six-bit length and two-bit pen.
ceremony_msx_flags:
        ld hl,msx_flag_fill
        ld de,CER_CMD
        ld bc,21
        ldir
        ld ix,msx_flag_tables
        ld iy,msx_flag_rows
        ld b,4
.next_flag:
        push bc
        ld l,(ix+0)
        ld h,(ix+1)
        inc ix
        inc ix
        ld e,(iy+0)
        ld d,(iy+1)
        inc iy
        inc iy
.row:
        ld a,(hl)
        inc hl
        cp 255
        jr z,.flag_done
        ld c,a
        ld a,(hl)
        inc hl
        ld (CER_CMD+4),a
        push hl
        ld h,0
        ld l,c
        add hl,de
        ld (CER_CMD+6),hl
        pop hl
.span:
        ld a,(hl)
        inc hl
        or a
        jr z,.row
        ld c,a
        srl a
        srl a
        ld (CER_CMD+8),a
        ld a,c
        and 3
        ld c,a
        ld b,0
        push hl
        ld hl,msx_flag_pens
        add hl,bc
        ld a,(hl)
        ld (CER_CMD+16),a
        ld (CER_CMD+17),a
        push de
        ld hl,CER_CMD
        call command
        pop de
        pop hl
        ld a,(CER_CMD+4)
        ld c,a
        ld a,(CER_CMD+8)
        add a,c
        ld (CER_CMD+4),a
        jr .span
.flag_done:
        pop bc
        djnz .next_flag
        ret
msx_flag_rows: dw CER_C,2816,3072,3328
msx_flag_pens: db 0x77,0x99,0x00,MSX_LOGO_PEN*17
msx_flag_fill:
        dw 0,0,0,0,0,1
        db 0,0x0c,0xff,0xff,0,0,0,0,0x20
        include "../build/step7/msx-flag.inc"

; A = ending picture, HL = VRAM row. The picture's palette is skipped.
ceremony_upload:
        di
        push hl
        ld e,a
        ld d,0
        ld hl,ending_frames
        add hl,de
        add hl,de
        add hl,de
        ld a,(hl)
        ld (0x7000),a
        ld (0xc839),a
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,48
        add hl,de
        pop de
        ; VRAM address = row * 128.
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
        call ending_upload_rle
        ei
        ret

ceremony:
        xor a
        ld (CER_HIDDEN),a
        ld (CER_DRAWN_A),a
        ld (CER_DRAWN_B),a
        ld hl,0
        ld (CER_FRAME),hl
        ld hl,512
        ld (CER_TOP),hl
        ld hl,CER_SLOTS
        ld b,CER_SLOT_COUNT*8
.clear:
        ld (hl),a
        inc hl
        djnz .clear
        ld hl,CEREMONY_CAPS_ADDR
        ld (CER_NEXT),hl
        ; Arms raised: copy A from the bottom, with the ceremony palette.
        call ceremony_vblank
        ld a,2
        call ceremony_palette
        ld hl,CER_A+512
        call ceremony_scroll
        ld b,48
.raised:
        push bc
        call ceremony_vblank
        pop bc
        djnz .raised
        ld a,1
        ld (CER_HIDDEN),a
.frame:
        ; The V9990 always runs at 60 Hz (R7 = 0): one arcade frame per
        ; V9990 frame, also on 50 Hz MSX computers.
        call ceremony_update
        call ceremony_draw
        call ceremony_vblank
        ld a,(CER_HIDDEN)
        or a
        ld hl,CER_A
        jr z,.base
        ld hl,CER_B
.base:
        ld de,(CER_TOP)
        add hl,de
        call ceremony_scroll
        ; Halfway up, the stage is leaving the frame and the flag is still
        ; out of view. Change the logo pen here, once, in this same VBlank.
        ld a,d
        cp 1
        jr nz,.logo_pen_ready
        ld a,e
        or a
        jr nz,.logo_pen_ready
        ld a,(0xf207)
        cp 1
        call z,ceremony_white_logo_pen
.logo_pen_ready:
        ld hl,CER_HIDDEN
        ld a,(hl)
        xor 1
        ld (hl),a
        ; Done when the camera has stopped and every cap has gone.
        ld hl,(CER_TOP)
        ld a,h
        or l
        jr nz,.frame
        ld hl,(CER_NEXT)
        ld a,(hl)
        inc hl
        and (hl)
        inc a
        jr nz,.frame
        ld hl,CER_SLOTS+7
        ld de,8
        ld b,CER_SLOT_COUNT
.alive:
        ld a,(hl)
        or a
        jr nz,.frame
        add hl,de
        djnz .alive
        ; The flag waves: four pictures of 10 arcade frames, about 10 s.
        ld c,60
.wave:
        ld hl,ceremony_waves
        ld a,c
        and 3
        add a,a
        ld e,a
        ld d,0
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        push bc
        call ceremony_vblank
        call ceremony_scroll
        ld b,9
.hold:
        push bc
        call ceremony_vblank
        pop bc
        djnz .hold
        pop bc
        dec c
        jr nz,.wave
        ; The alternative theme belongs only to the MSX flag.
        ld a,(0xf207)
        cp 1
        jr nz,.flag_music_done
        call psg_stop
.flag_music_done:
        ; Blank before the rank screen resets the scroll to page 0.
        call display_off        ; off from the next frame on
        ld hl,0
        jp ceremony_scroll

; Indexed by the decreasing counter AND 3: pictures 0, 1, 2, 3 in turn.
ceremony_waves:
        dw CER_C,3328,3072,2816

; A = ending picture whose 48-byte palette is written to the V9990.
ceremony_palette:
        ld e,a
        ld d,0
        ld hl,ending_frames
        add hl,de
        add hl,de
        add hl,de
        ld a,(hl)
        ld (0x7000),a
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ld bc,0x3061
        otir
        ld a,CEREMONY_CAPS_BANK
        ld (0x7000),a
        ret

; Called only at the midpoint of the MSX variant's rising scroll.
ceremony_white_logo_pen:
        ld a,14
        out (0x64),a
        ld a,MSX_LOGO_PEN*4
        out (0x63),a
        ld a,31
        out (0x61),a
        out (0x61),a
        out (0x61),a
        ret

; HL = first displayed VRAM row (SCAY, R17 and R18).
ceremony_scroll:
        ld a,17
        out (0x64),a
        ld a,l
        out (0x63),a
        ld a,h
        out (0x63),a
        ret

; Waits for the start of the next V9990 vertical blank.
ceremony_vblank:
.end:
        in a,(0x65)
        bit 6,a
        jr nz,.end
.start:
        in a,(0x65)
        bit 6,a
        jr z,.start
        ret

; One arcade frame: camera, new caps and cap movement.
ceremony_update:
        ld hl,(CER_FRAME)
        ld de,256
        or a
        sbc hl,de
        jr nc,.top_ready
        ld hl,(CER_TOP)
        dec hl
        dec hl
        ld (CER_TOP),hl
.top_ready:
        ; Advance the caps already flying.
        ld ix,CER_SLOTS
        ld b,CER_SLOT_COUNT
.move:
        ld a,(ix+7)
        or a
        jr z,.move_next
        ld a,(ix+2)
        or (ix+3)
        jr nz,.read
        ld (ix+7),a             ; no steps left: gone
        jr .move_next
.read:
        ld l,(ix+0)
        ld h,(ix+1)
        ld a,(hl)
        inc hl
        ld (ix+0),l
        ld (ix+1),h
        ld l,(ix+2)
        ld h,(ix+3)
        dec hl
        ld (ix+2),l
        ld (ix+3),h
        ld c,a
        rlca
        rlca
        rlca
        and 7
        ld (ix+6),a             ; picture
        ld a,c
        and 31                  ; (dx+2)*5 + (dy+2)
        ld c,-2
.dx:
        sub 5
        jr c,.dx_ready
        inc c
        jr .dx
.dx_ready:
        add a,5-2               ; dy
        add a,(ix+5)
        ld (ix+5),a
        ld a,c
        add a,(ix+4)
        ld (ix+4),a
.move_next:
        ld de,8
        add ix,de
        djnz .move
        ; Caps whose track starts at this frame.
.spawn:
        ld hl,(CER_NEXT)
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        ld hl,(CER_FRAME)
        or a
        sbc hl,de
        pop hl
        jr nz,.spawned
        ld ix,CER_SLOTS
        ld b,CER_SLOT_COUNT
.free:
        ld a,(ix+7)
        or a
        jr z,.found
        ld de,8
        add ix,de
        djnz .free
        jr .spawned             ; every slot busy (never in the capture)
.found:
        ld a,(hl)
        ld (ix+4),a             ; x
        inc hl
        ld a,(hl)
        ld (ix+5),a             ; y
        inc hl
        ld a,(hl)
        ld (ix+6),a             ; picture
        inc hl
        ld a,(hl)
        ld (ix+2),a
        inc hl
        ld a,(hl)
        ld (ix+3),a             ; steps
        inc hl
        ld (ix+0),l
        ld (ix+1),h
        ld e,(ix+2)
        ld d,(ix+3)
        add hl,de
        ld (CER_NEXT),hl
        ld (ix+7),1
        jr .spawn
.spawned:
        ld hl,(CER_FRAME)
        inc hl
        ld (CER_FRAME),hl
        ret

; Restores the caps of the hidden copy and draws the current ones on it.
ceremony_draw:
        ld a,(CER_HIDDEN)
        or a
        ld ix,CER_DRAWN_A
        ld hl,CER_A
        jr z,.copy_ready
        ld ix,CER_DRAWN_B
        ld hl,CER_B
.copy_ready:
        ld (CER_CMD+21),hl      ; base row of the hidden copy (scratch)
        ; Restore: opaque copies from the clean scene C.
        ld b,(ix+0)
        push ix
        inc ix
        ld a,b
        or a
        jr z,.restored
.restore:
        push bc
        ld hl,ceremony_restore_template
        call ceremony_cap_command
        pop bc
        ld de,4
        add ix,de
        djnz .restore
.restored:
        pop ix
        ld (ix+0),0
        ; Draw: transparent copies from the cap pictures.
        push ix
        pop iy
        inc iy                  ; next free entry of the drawn list
        ld hl,CER_SLOTS
        ld b,CER_SLOT_COUNT
.cap:
        push bc
        push hl
        push hl
        pop ix
        ld a,(ix+7)
        or a
        jr z,.cap_next
        ; Scene row = top + (y - 9); off the scene top or bottom: not drawn.
        ld a,(ix+5)
        sub 9
        ld e,a
        ld d,0
        jr nc,.row
        dec d
.row:
        ld hl,(CER_TOP)
        add hl,de
        bit 7,h
        jr nz,.cap_next
        ld a,(ix+4)             ; drawn list: x, scene row, picture
        ld (iy+0),a
        ld (iy+1),l
        ld (iy+2),h
        ld a,(ix+6)
        ld (iy+3),a
        push iy
        pop ix
        ld hl,ceremony_cap_template
        call ceremony_cap_command
        ld de,4
        add iy,de
        ld a,(CER_HIDDEN)
        or a
        ld hl,CER_DRAWN_A
        jr z,.count
        ld hl,CER_DRAWN_B
.count:
        inc (hl)
.cap_next:
        pop hl
        ld de,8
        add hl,de
        pop bc
        djnz .cap
        ret

; HL = template; IX = drawn entry (x, scene row word, picture).
; Restore template: source C; cap template: source the cap picture.
ceremony_cap_command:
        ld de,CER_CMD
        ld bc,21
        ldir
        ld a,(ix+3)
        add a,a
        ld e,a
        ld d,0
        ld hl,ceremony_cap_size
        add hl,de
        ld a,(hl)               ; width
        ld c,a
        inc hl
        ld a,(hl)
        ld (CER_CMD+10),a       ; NY
        ld a,(CER_CMD+3)        ; SY high: C (restore) or the cap pictures
        cp CER_C/256
        jr nz,.cap_source
        ; Restore: SX = x, SY = C + scene row.
        ld a,(ix+0)
        ld (CER_CMD+0),a
        ld l,(ix+1)
        ld h,(ix+2)
        ld de,CER_C
        add hl,de
        ld (CER_CMD+2),hl
        jr .destination
.cap_source:
        ld a,(ix+3)
        add a,a
        add a,a
        add a,a
        add a,a
        ld (CER_CMD+0),a        ; SX = 16 * picture
.destination:
        ld a,(ix+0)
        ld (CER_CMD+4),a        ; DX
        ld b,a
        ld a,c
        add a,b
        jr nc,.width
        ld a,b
        neg
        ld c,a                  ; clipped at the right edge
.width:
        ld a,c
        ld (CER_CMD+8),a        ; NX
        ld l,(ix+1)
        ld h,(ix+2)
        ld de,(CER_CMD+21)
        add hl,de
        ld (CER_CMD+6),hl       ; DY = copy base + scene row
        ld hl,CER_CMD
        jp command

ceremony_scene_template:
        dw 0,CER_C,0,0,256,724
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
ceremony_restore_template:
        dw 0,CER_C,0,0,0,0
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
ceremony_cap_template:
        dw 0,CER_CAPS_Y,0,0,0,0
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
