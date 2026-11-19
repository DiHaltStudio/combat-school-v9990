; RANKING table and the arcade's text screens, in a bank of their own run
; at page 1 (0x4000): the same bank as the final mission's ending tables
; (tools/build_mission_visual.py), which the mission reads at page 2.
;
; 0x4010: after GAME OVER in any step (src/penalty.asm): the RANKING table
;         with the game score (c75c..c75e), initials if it enters the table,
;         then the cartridge title.
; 0x4013: the end of the game (src/mission_boss.asm, after the mansion):
;         "YOUR TITLE" with the officer rank blinking, the fade to black,
;         "CONGRATULATIONS! THANK YOU FOR PLAYING", the RANKING table with
;         initials, then the title.
; The title is bank 0, 0x4010 (the standalone mission restarts).
;
; Text: the arcade 8x8 font (tools/extract_mission_ending.py: glyph pixels
; and shadow) at VRAM rows 1536 and 1552, one coloured copy per palette
; entry 2..14 at rows 1568 + 16 * colour (copy, AND with the colour, shadow
; over it); a glyph is one LMMM. Blink, colour cycle and fade only change
; the palette. Frames are V9990 frames (60 Hz on every MSX).
;
; Initials as in the arcade: right/up the next character, left/down the
; previous one (A..Z, space, '.', '!', '?', END), space or button 1 takes
; it; three characters, END or 1040 frames end the entry. The character
; being chosen uses the cycling colour of the title.
;
; RAM: D0C0 command (21 bytes), D0D6 colour override, D0D7 text column,
; D0D8 text row, D0D9 frames left (word), D0DB cycle step, D0DC frames to
; the next step, D0DD character index, D0DE initial being entered, D0DF
; input (bit 0 next, 1 previous, 2 take) and D0E8 the previous one, D0E0
; six digit glyphs, D0E7 frames to the auto-repeat, D0E8 officer rank,
; D0E9 table place (255: none), D0EA score (3 bytes), D0ED entry frames
; left (word), D100 palette (48 bytes).
; The table stays in F300 (signature "CS", then ten entries: score
; 24-bit, initials, title) while the computer is on.

END_CMD equ 0xd0c0
END_COLOUR equ 0xd0d6
END_X equ 0xd0d7
END_Y equ 0xd0d8
END_LEFT equ 0xd0d9
END_STEP equ 0xd0db
END_NEXT equ 0xd0dc
END_CHAR equ 0xd0dd
END_CELL equ 0xd0de
END_INPUT equ 0xd0df
END_DIGITS equ 0xd0e0
END_REPEAT equ 0xd0e7
END_RANK equ 0xd0e8
END_POS equ 0xd0e9
END_SCORE equ 0xd0ea
END_ENTRY equ 0xd0ed
END_LAST equ 0xd0ef
END_PAL equ 0xd100
END_TABLE equ 0xf300
END_FONT_ROW equ 1536
END_SHADOW_ROW equ 1552
END_COLOUR_ROW equ 1568

        org 0x4000
        ds 0x4010-$,0xff
        jp rank_game_over
        jp rank_ending

rank_game_over:
        di
        ld sp,0xf000
        call rank_start
        ei                      ; the music ticks on the interrupt (the mission
                                ; and GAME OVER may have left it off)
        call end_ranking_screen
        jr rank_title

rank_ending:
        di
        ld sp,0xf000
        call rank_start
        ei                      ; the music ticks on the interrupt (the mission
                                ; and GAME OVER may have left it off)
        call end_rank_screen
        call end_congrats_screen
        call end_ranking_screen
rank_title:
        di
        ld a,(0xfda1)           ; the RANKING music loops: silent for the title
        cp PSG_CALL_HOOK
        jr nz,.silent
        ld hl,0
        ld (PSG_CALL_ARC_ON),hl
        call PSG_CALL_STOP
        ld bc,3*256+8
.mute:
        ld a,c
        out (0xa0),a
        xor a
        out (0xa1),a
        inc c
        djnz .mute
.silent:
        ld hl,end_title_jump
        ld de,0xf2a0
        ld bc,end_title_jump_end-end_title_jump
        ldir
        ld sp,0xf000
        jp 0xf2a0
end_title_jump:
        xor a
        ld (0x6000),a
        jp 0x4010
end_title_jump_end:

; psg_play of src/psg_calls.asm for this bank (the mission's copy, which
; defines PSG_CALL_*, is not mapped here). A = song; keeps every register.
rank_psg_play:
        push af
        ld a,(0xfda1)
        cp PSG_CALL_HOOK
        jr nz,.none
        push hl
        ld hl,0
        ld (PSG_CALL_STREAM),hl
        ld (PSG_CALL_DEFER),hl  ; ticks from the interrupt again
        ld (PSG_CALL_ARC_ON),hl ; no arcade song
        pop hl
        pop af
        push af
        call PSG_CALL_START
.none:
        pop af
        ret

; psg_arcade of src/psg_calls.asm for this bank: A = arcade song (ARC_*);
; the songs' bank stays at page 2, which this module does not use. Keeps
; BC, DE, HL; enables interrupts.
rank_psg_arcade:
        push af
        ld a,(0xfda1)
        cp PSG_CALL_HOOK
        jr nz,.none
        pop af
        push af
        push bc
        push de
        push hl
        call PSG_CALL_ARC_LOAD  ; also ends the hats and the deferred ticks
        ld hl,0
        ld (PSG_CALL_DEFER),hl
        pop hl
        pop de
        pop bc
.none:
        pop af
        ret

; B1 at 256 x 212, display off, black, no scroll; the font. The score is
; held to 999999, the six digits shown.
rank_start:
        ld a,(0xc75e)
        cp 0x0f
        jr c,.score_ok
        jr nz,.score_cap
        ld hl,(0xc75c)
        ld de,0x4240
        or a
        sbc hl,de
        jr c,.score_ok
.score_cap:
        ld hl,0x423f            ; 999999 = 0x0f423f
        ld (0xc75c),hl
        ld a,0x0f
        ld (0xc75e),a
.score_ok:
        call end_blank          ; R8 is latched per frame: no flash
        ld a,6
        out (0x64),a
        ld hl,rank_regs
        ld bc,0x0463
        otir
        ld a,13
        out (0x64),a
        ld hl,rank_settings
        ld bc,0x0863
        otir
        ld hl,rank_black
        call end_palette_set
        call end_setup
        jp end_clear
rank_regs: db 0x81,0,0x42,0
rank_settings: db 0,0,0,0,0,0,0,0

; HL = 21-byte V9990 command (R32..R52) once the previous one ends.
end_command:
        in a,(0x65)
        rrca
        jr c,end_command
        ld a,32
        out (0x64),a
        ld bc,21*256+0x63
        otir
        ret

; HL = count/value RLE pairs ended by a zero count, to the VRAM address set.
end_upload:
        ld b,(hl)
        inc hl
        ld a,b
        or a
        ret z
        ld a,(hl)
        inc hl
.emit:
        out (0x60),a
        djnz .emit
        jr end_upload

; Waits for the start of the next V9990 vertical blanking.
; The ranking runs from its own bank (ENDING_BANK): display_off of
; src/psg_calls.asm is in the mission's bank, so it has this copy. Display
; off, then a whole frame started off (R8 is read when a frame starts).
end_blank:                              ; as display_off (src/psg_calls.asm)
        ld a,i
        push af
        di
        call end_vblank
        ld a,8
        out (0x64),a
        ld a,0x42
        out (0x63),a
        pop af
        jp po,.started
        ei
.started:
        in a,(0x65)
        bit 6,a
        jr nz,.started
        ret
end_vblank:
        in a,(0x65)
        bit 6,a
        jr nz,end_vblank
.start:
        in a,(0x65)
        bit 6,a
        jr z,.start
        ret

; A = page (0/1): SCAY = 256 * page.
end_show:
        ld b,a
        ld a,17
        out (0x64),a
        xor a
        out (0x63),a
        ld a,b
        out (0x63),a
        ret

end_clear_cmd:
        dw 0,0,0,0,256,512
        db 0,0x0c,0xff,0xff,0,0,0,0,0x20

; Font in VRAM and its coloured copies; the command template.
end_setup:
        ld hl,end_template
        ld de,END_CMD
        ld bc,21
        ldir
        ld de,END_FONT_ROW
        call end_vram_row
        ld hl,end_font_fg
        call end_upload
        ld de,END_SHADOW_ROW
        call end_vram_row
        ld hl,end_font_shadow
        call end_upload
        ld hl,256
        ld (END_CMD+8),hl       ; NX
        ld hl,16
        ld (END_CMD+10),hl      ; NY
        ld hl,0
        ld (END_CMD+0),hl
        ld (END_CMD+4),hl
        ld c,2
.colour:
        ld l,c
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,END_COLOUR_ROW
        add hl,de
        ld (END_CMD+6),hl       ; DY
        ld hl,END_FONT_ROW
        ld de,0x0c40            ; opaque copy
        call .command
        ld a,c
        rlca
        rlca
        rlca
        rlca
        or c
        ld (END_CMD+16),a
        ld (END_CMD+17),a       ; FC = colour in every pixel
        ld de,0x0820            ; LMMV, AND
        call .command
        ld hl,END_SHADOW_ROW
        ld de,0x1c40            ; transparent copy
        call .command
        inc c
        ld a,c
        cp 15
        jr c,.colour
        ld hl,8
        ld (END_CMD+8),hl
        ld (END_CMD+10),hl      ; glyphs: 8 x 8
        ld a,0x0c
        ld (END_CMD+13),a
        ld a,0x40
        ld (END_CMD+20),a
        ret
; HL = SY, D = LOP, E = opcode.
.command:
        ld (END_CMD+2),hl
        ld a,d
        ld (END_CMD+13),a
        ld a,e
        ld (END_CMD+20),a
        push bc
        ld hl,END_CMD
        call end_command
        pop bc
        ret

; DE = VRAM row: write address at its start (x = 0).
end_vram_row:
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
        ret

end_template:
        dw 0,0,0,0,8,8
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40

; Clears both pages, shows page 0 (display still off).
end_clear:
        ld hl,end_clear_cmd
        call end_command
        xor a
        jp end_show

; HL = text list (see tools/mission_ending_data.py). END_COLOUR, when not 0,
; replaces the colours.
end_texts:
        ld a,(hl)
        cp 255
        ret z
        ld (END_X),a
        inc hl
        ld a,(hl)
        ld (END_Y),a
        inc hl
        ld c,(hl)
        inc hl
        ld a,(END_COLOUR)
        or a
        jr z,.glyphs
        ld c,a
.glyphs:
        call end_glyphs
        jr end_texts

; HL = glyphs ended by 255, C = colour, at END_X, END_Y; HL after the end.
end_glyphs:
        ld a,(hl)
        inc hl
        cp 255
        ret z
        call end_glyph
        jr end_glyphs

; A = glyph (254: space), C = colour at END_X, END_Y; next column.
end_glyph:
        cp 254
        jr z,.next
        push hl
        push bc
        ld b,a
        and 31
        add a,a
        add a,a
        add a,a
        ld (END_CMD+0),a        ; SX
        ld a,b
        and 0xe0
        rrca
        rrca                    ; (glyph / 32) * 8
        ld e,a
        ld l,c
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld d,0
        add hl,de
        ld de,END_COLOUR_ROW
        add hl,de
        ld (END_CMD+2),hl       ; SY
        ld a,(END_X)
        add a,a
        add a,a
        add a,a
        ld (END_CMD+4),a        ; DX
        ld a,(END_Y)
        ld (END_CMD+6),a        ; DY (page 0)
        xor a
        ld (END_CMD+5),a
        ld (END_CMD+7),a
        ld hl,END_CMD
        call end_command
        pop bc
        pop hl
.next:
        ld a,(END_X)
        inc a
        ld (END_X),a
        ret

; END_SCORE (24-bit) to six glyphs at END_DIGITS, leading zeros as spaces.
end_digits:
        ld hl,(END_SCORE)
        ld a,(END_SCORE+2)
        ld ix,end_divisors
        ld iy,END_DIGITS
        ld b,6
.digit:
        ld e,(ix+0)
        ld d,(ix+1)
        ld c,(ix+2)
        ld (iy+0),END_G0
.subtract:
        or a
        sbc hl,de
        sbc a,c
        jr c,.restore
        inc (iy+0)
        jr .subtract
.restore:
        add hl,de
        adc a,c
        inc ix
        inc ix
        inc ix
        inc iy
        djnz .digit
        ld hl,END_DIGITS
        ld b,5
.leading:
        ld a,(hl)
        cp END_G0
        ret nz
        ld (hl),END_GSPACE
        inc hl
        djnz .leading
        ret
end_divisors:
        db 0xa0,0x86,0x01, 0x10,0x27,0, 0xe8,0x03,0, 100,0,0, 10,0,0, 1,0,0

; D = column, E = row, C = colour: the six digits of END_SCORE.
end_number:
        push bc
        push de
        push ix
        call end_digits
        pop ix
        pop de
        pop bc
        ld a,d
        ld (END_X),a
        ld a,e
        ld (END_Y),a
        ld hl,END_DIGITS
        ld b,6
.glyph:
        ld a,(hl)
        inc hl
        call end_glyph
        djnz .glyph
        ret

; Officer rank of the game score (c75c): 0 captain .. 7 rookie, strictly
; over each threshold.
end_officer:
        ld ix,end_thresholds
        ld b,0
.rank:
        ld hl,(0xc75c)
        ld a,(0xc75e)
        ld e,(ix+0)
        ld d,(ix+1)
        or a
        sbc hl,de
        sbc a,(ix+2)
        jr c,.next              ; below
        or h
        or l
        jr nz,.found            ; over (equal is not)
.next:
        inc ix
        inc ix
        inc ix
        inc b
        ld a,b
        cp END_RANKS-1
        jr c,.rank
.found:
        ld a,b
        ld (END_RANK),a
        ret

; HL = 48 bytes: the palette, also kept at END_PAL for the fade.
end_palette_set:
        ld de,END_PAL
        ld bc,48
        ldir
end_palette_show:
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ld hl,END_PAL
        ld bc,0x3061
        otir
        ret

; A = entry, HL = R, G, B: palette entry written and kept.
end_set_entry:
        push af
        ld e,a
        add a,a
        add a,e
        ld e,a
        ld d,0
        push hl
        ld hl,END_PAL
        add hl,de
        ex de,hl
        pop hl
        push hl
        ldi
        ldi
        ldi
        pop hl
        ld a,14
        out (0x64),a
        pop af
        add a,a
        add a,a
        out (0x63),a
        ld bc,0x0361
        otir
        ret

end_display_on:
        call end_vblank
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ret

end_display_off:
        call end_vblank
        call end_blank          ; off from the next frame on
        ret

; HL = frames to wait.
end_frames:
        push hl
        call end_vblank
        pop hl
        dec hl
        ld a,h
        or l
        jr nz,end_frames
        ret

; Officer rank screen: 577 frames, the reached rank blinking (cyan, pink:
; first change after 11 frames, then every 8), then a fade to black
; (one step every 2 frames) and black.
end_rank_screen:
        ld a,ARC_TITLE          ; YOUR TITLE: the arcade's 38h
        call rank_psg_arcade
        call end_officer
        call end_clear
        xor a
        ld (END_COLOUR),a
        ld hl,end_rank_texts
        call end_texts
        ld b,0
.block:
        push bc
        ld a,(END_RANK)
        cp b
        ld a,0
        jr nz,.colour
        ld a,14
.colour:
        ld (END_COLOUR),a
        ld l,b
        ld h,0
        add hl,hl
        ld de,end_rank_blocks
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        call end_texts
        pop bc
        inc b
        ld a,b
        cp END_RANKS
        jr c,.block
        xor a
        ld (END_COLOUR),a
        ld a,1
        ld (END_X),a
        ld a,(END_RANK)
        ld e,a
        ld d,0
        ld hl,end_rank_rows
        add hl,de
        ld a,(hl)
        ld (END_Y),a
        ld hl,end_arrow
        ld c,12
        call end_glyphs
        ld hl,(0xc75c)
        ld (END_SCORE),hl
        ld a,(0xc75e)
        ld (END_SCORE+2),a      ; for the RANKING; not shown here (user)
        ld hl,end_palette
        call end_palette_set
        call end_display_on
        ld a,11
        ld (END_NEXT),a
        xor a
        ld (END_STEP),a
        ld hl,577
        ld (END_LEFT),hl
.frame:
        call end_vblank
        ld hl,END_NEXT
        dec (hl)
        jr nz,.counted
        ld (hl),8
        ld a,(END_STEP)
        xor 1
        ld (END_STEP),a
        ld hl,end_blink
        jr z,.blink
        inc hl
        inc hl
        inc hl
.blink:
        ld a,14
        call end_set_entry
.counted:
        ld hl,(END_LEFT)
        dec hl
        ld (END_LEFT),hl
        ld a,h
        or l
        jr nz,.frame
        ; Fade: every component down by one each 2 frames.
        ld b,31
.fade:
        push bc
        ld hl,END_PAL
        ld b,48
.component:
        ld a,(hl)
        or a
        jr z,.dark
        dec (hl)
.dark:
        inc hl
        djnz .component
        call end_vblank
        call end_vblank
        call end_palette_show
        pop bc
        djnz .fade
        call end_display_off
        ld hl,102-2
        jp end_frames

; CONGRATULATIONS: 383 frames, then 3 black.
end_congrats_screen:
        call end_clear
        ld hl,end_congrats_texts
        call end_texts
        ld hl,end_palette
        call end_palette_set
        call end_display_on
        ld hl,383
        call end_frames
        call end_display_off
        ld hl,3
        jp end_frames

rank_black: ds 48,0

; RANKING: the game score enters the table if it beats an entry (the
; entries below move down), the initials are taken, then the table stays
; 240 frames more (600 frames when the score does not enter it). The title
; changes colour every 4 frames.
end_ranking_screen:
        ld a,ARC_RANKING        ; RANKING music: the arcade's 24h (src/psg_arcade.asm)
        call rank_psg_arcade
        call end_officer
        ld hl,(END_TABLE)
        ld de,'C'+'S'*256
        or a
        sbc hl,de
        jr z,.table
        ld (END_TABLE),de
        ld hl,end_defaults
        ld de,END_TABLE+2
        ld bc,70
        ldir
.table:
        ld a,255
        ld (END_POS),a
        ; Place: the first entry with a lower score.
        ld ix,END_TABLE+2
        ld b,0
.find:
        ld l,(ix+0)
        ld h,(ix+1)
        ld de,(0xc75c)
        ld a,(0xc75e)
        or a
        sbc hl,de
        ld e,a
        ld a,(ix+2)
        sbc a,e                 ; entry - score
        jr c,.insert
        ld de,7
        add ix,de
        inc b
        ld a,b
        cp 10
        jr c,.find
        jr .draw
.insert:
        ld a,b
        ld (END_POS),a
        ; Entries b..8 move down one place (the last one leaves).
        ld a,9
        sub b
        jr z,.place
        ld l,a
        ld h,0
        ld e,l
        ld d,h
        add hl,hl
        add hl,hl
        add hl,hl
        or a
        sbc hl,de               ; (9 - b) * 7 bytes
        ld c,l
        ld b,h
        ld hl,END_TABLE+2+9*7-1
        ld de,END_TABLE+2+10*7-1
        lddr
.place:
        ld hl,(0xc75c)
        ld (ix+0),l
        ld (ix+1),h
        ld a,(0xc75e)
        ld (ix+2),a
        ld a,END_GSPACE
        ld (ix+3),a
        ld (ix+4),a
        ld (ix+5),a
        ld a,(END_RANK)
        ld (ix+6),a
.draw:
        call end_clear
        ld hl,end_ranking_texts
        call end_texts
        ld ix,END_TABLE+2
        ld b,0
.row:
        push bc
        ld a,b
        call end_row_colour
        ld a,b
        call end_row_y
        ld e,a
        ld l,(ix+0)
        ld h,(ix+1)
        ld (END_SCORE),hl
        ld a,(ix+2)
        ld (END_SCORE+2),a
        push de
        ld d,10
        call end_number
        pop de
        ld a,e
        ld (END_Y),a
        ld a,19
        ld (END_X),a
        ld a,(ix+3)
        call end_glyph
        ld a,(ix+4)
        call end_glyph
        ld a,(ix+5)
        call end_glyph
        ld a,23
        ld (END_X),a
        ld a,(ix+6)
        ld l,a
        add a,a
        add a,a
        add a,a
        add a,l                 ; title * 9
        ld e,a
        ld d,0
        ld hl,end_titles
        add hl,de
        ld b,9
.title:
        ld a,(hl)
        inc hl
        call end_glyph
        djnz .title
        ld de,7
        add ix,de
        pop bc
        inc b
        ld a,b
        cp 10
        jr c,.row
        ld hl,end_palette
        call end_palette_set
        xor a
        ld (END_STEP),a
        inc a
        ld (END_NEXT),a
        ld hl,600
        ld a,(END_POS)
        cp 255
        jr z,.time
        call end_entry_start
        ld hl,1280
.time:
        ld (END_LEFT),hl
        call end_display_on
.frame:
        ld hl,END_NEXT
        dec (hl)
        jr nz,.wait
        ld (hl),4
        ld a,(END_STEP)
        ld l,a
        add a,a
        add a,l
        ld e,a
        ld d,0
        ld hl,end_title_cycle
        add hl,de
        ld a,13
        call end_set_entry
        ld a,(END_STEP)
        inc a
        cp END_CYCLE_LEN
        jr c,.step
        xor a
.step:
        ld (END_STEP),a
.wait:
        call end_vblank
        ld a,(END_POS)
        cp 255
        call nz,end_entry_tick
        ld hl,(END_LEFT)
        dec hl
        ld (END_LEFT),hl
        ld a,h
        or l
        jr nz,.frame
        call end_display_off
        ld hl,5
        jp end_frames

; A = table place: C = its colour.
end_row_colour:
        push hl
        ld e,a
        ld d,0
        ld hl,end_ranking_colours
        add hl,de
        ld c,(hl)
        pop hl
        ret

; A = table place: A = its row (56 + 16 * place).
end_row_y:
        add a,a
        add a,a
        add a,a
        add a,a
        add a,56
        ret

; IX = the player's table entry.
end_entry_ix:
        ld a,(END_POS)
        ld e,a
        add a,a
        add a,a
        add a,a
        sub e                   ; place * 7
        ld e,a
        ld d,0
        ld ix,END_TABLE+2
        add ix,de
        ret

; END_X = 19 + cell, END_Y = the player's row.
end_entry_xy:
        ld a,(END_CELL)
        add a,19
end_entry_at:
        ld (END_X),a
        ld a,(END_POS)
        call end_row_y
        ld (END_Y),a
        ret

; "1P>" before the initials; the first character (A) being chosen.
end_entry_start:
        xor a
        ld (END_CHAR),a
        ld (END_CELL),a
        ld (END_REPEAT),a
        ld hl,1040
        ld (END_ENTRY),hl
        call end_read_input
        ld (END_LAST),a         ; a key already held does not count
        ld a,16
        call end_entry_at
        ld hl,end_arrow
        ld c,12
        call end_glyphs
        jp end_entry_draw

; The character being chosen, in the cycling colour (entry 13).
end_entry_draw:
        call end_entry_xy
        call end_erase
        call end_char_glyph
        ld c,13
        jp end_glyph

; A = the glyph of the character being chosen.
end_char_glyph:
        ld a,(END_CHAR)
        ld e,a
        ld d,0
        ld hl,end_name_chars
        add hl,de
        ld a,(hl)
        ret

; One frame of the initials: moves, auto-repeat after 20 frames then every
; 8, takes the character on a new press.
end_entry_tick:
        ld hl,(END_ENTRY)
        dec hl
        ld (END_ENTRY),hl
        ld a,h
        or l
        jp z,end_entry_done
        call end_read_input
        ld c,a
        ld a,(END_LAST)
        ld b,a
        ld a,c
        ld (END_LAST),a
        ld a,b
        cpl
        and c
        ld d,a                  ; new presses
        and 3
        jr nz,.first
        ld a,c
        and 3
        jr z,.take
        ld hl,END_REPEAT
        dec (hl)
        jr nz,.take
        ld (hl),8
        jr .move
.first:
        ld hl,END_REPEAT
        ld (hl),20
.move:
        ld a,c
        ld hl,END_CHAR
        rrca
        ld a,(hl)
        jr nc,.previous
        inc a
        cp END_NAME_CHARS
        jr c,.set
        xor a
        jr .set
.previous:
        or a
        jr nz,.down
        ld a,END_NAME_CHARS
.down:
        dec a
.set:
        ld (hl),a
        push de
        call end_entry_draw
        pop de
.take:
        bit 2,d
        ret z
        ld a,(END_CHAR)
        cp END_NAME_CHARS-1     ; END
        jr z,end_entry_done
        call end_entry_ix
        ld a,(END_CELL)
        add a,3
        ld e,a
        ld d,0
        add ix,de
        call end_char_glyph
        ld (ix+0),a
        ld hl,END_CELL
        inc (hl)
        ld a,(hl)
        cp 3
        jr z,end_entry_done
        jp end_entry_draw       ; the next one starts on the same character

; Initials taken: "1P>" goes, the initials in the row's colour; the table
; stays 240 frames more.
end_entry_done:
        ld a,16
        call end_entry_at
        ld b,6
.erase:
        push bc
        call end_erase
        ld hl,END_X
        inc (hl)
        pop bc
        djnz .erase
        ld a,19
        call end_entry_at
        call end_entry_ix
        ld a,(END_POS)
        call end_row_colour
        ld a,(ix+3)
        call end_glyph
        ld a,(ix+4)
        call end_glyph
        ld a,(ix+5)
        call end_glyph
        ld a,255
        ld (END_POS),a
        ld hl,240
        ld (END_LEFT),hl
        ret

; The 8 x 8 cell at END_X, END_Y in black.
end_erase:
        ld a,(END_X)
        add a,a
        add a,a
        add a,a
        ld (END_CMD+4),a
        ld a,(END_Y)
        ld (END_CMD+6),a
        xor a
        ld (END_CMD+5),a
        ld (END_CMD+7),a
        ld (END_CMD+16),a
        ld (END_CMD+17),a
        ld a,0x20               ; LMMV
        ld (END_CMD+20),a
        ld hl,END_CMD
        call end_command
        ld a,0x40               ; LMMM again for the glyphs
        ld (END_CMD+20),a
        ret

; A: bit 0 right or up, bit 1 left or down (cursor keys or joystick 1),
; bit 2 space or button 1.
end_read_input:
        xor a
        call 0x00d5             ; GTSTCK: cursor keys
        or a
        jr nz,.direction
        ld a,1
        call 0x00d5             ; joystick 1
.direction:
        ld c,0
        or a
        jr z,.fire
        cp 4
        jr nc,.back
        ld c,1                  ; 1..3: up, up-right, right
        jr .fire
.back:
        cp 5
        jr c,.fire
        cp 8
        jr nc,.fire
        ld c,2                  ; 5..7: down, down-left, left
.fire:
        push bc
        xor a
        call 0x00d8             ; GTTRIG: space
        push af
        ld a,1
        call 0x00d8             ; joystick 1, button A
        pop bc
        or b
        pop bc
        ld a,c
        ret z
        or 4
        ret
