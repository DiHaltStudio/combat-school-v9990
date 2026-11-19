; Arm wrestling: front introduction, overhead contest and result.
        org 0x4000
        db "AB"
        dw init
        dw 0,0,0
        ds 6,0
init:
        di
        call 0x0138
        rrca
        rrca
        and 3
        ld c,a
        ld b,0
        ld hl,0xfcc1
        add hl,bc
        ld a,(hl)
        and 0x80
        or c
        ld c,a
        bit 7,a
        jr z,.slot_ready
        ; HL points at EXPTBL[primary]. The corresponding SLTTBL
        ; entry gives page 1's subslot in the ENASLT ID's bits 3..2.
        inc hl
        inc hl
        inc hl
        inc hl
        ld a,(hl)
        and 0x0c
        or c
.slot_ready:
        ld h,0x80
        call 0x0024
        di
        xor a
        ld (0xf3db),a          ; BIOS CLIKSW: disable the keyboard click
        ld sp,0xf000
        call display_off        ; off before the reset, which shows P1 garbage
        ld a,2
        out (0x67),a
        xor a
        out (0x67),a
        out (0x6f),a
        ld a,6
        out (0x64),a
        ld hl,regs
        ld bc,0x0463
        otir
        ld a,13
        out (0x64),a
        ld hl,settings
        ld bc,0x0863
        otir
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ; Front at y=512, top view at y=768, animation atlas at y=1024.
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        ld a,1
        out (0x63),a
        ld a,1
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ld a,2
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ld a,3
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ld a,4
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ld a,5
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        xor a
        ld (0xc880),a     ; phase: intro, play, result
        ld (0xc881),a     ; player power
        ld (0xc884),a     ; previous key
        ld (0xc885),a     ; frame counter
        ld (0xc886),a     ; hidden page
        ld (0xc88c),a     ; winner: 1 player, 2 CPU
        ld (0xc895),a     ; CPU bonus points, low byte
        ld (0xc896),a     ; CPU bonus points, high byte
        ld (0xc897),a     ; CPU bonus seconds
        ld (0xc882),a     ; CPU power (0..64, as the arcade bar)
        ld (0xc89a),a     ; 4-frame ticks since the overhead view began
        ld (0xc89d),a     ; clock tenths
        ld a,50
        ld (0xc883),a     ; hand position: 0 CPU wins, 100 player wins
        ld hl,3200
        ld (0xc898),hl    ; the same position in 1/64 units
        xor a             ; standalone starts without a preceding bonus
        add a,30
        ld (0xc887),a
        ld a,(0x002b)
        bit 7,a
        ld a,60
        jr z,.rate
        ld a,50
.rate:
        ld (0xc888),a
        ; Arcade timing in 4-frame ticks: one second (15 or 12) and the end
        ; of the CPU surge, 4 s + 5 ticks after the overhead view begins.
        srl a
        srl a
        ld (0xc89b),a
        ld b,a
        add a,a
        add a,a
        add a,5
        ld (0xc89c),a
        ; Power per press and hand speed factor, by frame rate.
        ld a,b
        cp 15
        ld hl,8+5*256
        jr z,.gain
        ld hl,7+6*256
.gain:
        ld (0xc89f),hl
        ; Jiffies per tenth of a second: 6 at 60 Hz, 5 at 50 Hz.
        ld a,(0xc888)
        ld b,-1
.tenth_rate:
        inc b
        sub 10
        jr nc,.tenth_rate
        ld a,b
        ld (0xc89e),a
        ld hl,(0xfc9e)
        ld (0xc889),hl
        ld (0xc88d),hl    ; phase start
        ld a,14
        ld (0xc418),a
        ld a,5                  ; arm wrestling music (src/psg_calls.asm)
        call psg_play
        ei
loop:
        ld a,(0xc880)
        or a
        jr z,.intro
        dec a
        jr z,.playing
        call result_tick
        jr .frame
.intro:
        ld a,4
        call elapsed_seconds
        jr c,.frame
        ld a,1
        ld (0xc880),a
        jr .frame
.playing:
        call update_input
        ld a,(0xc885)
        and 3
        jr nz,.contest_ready
        ld hl,0xc89a
        inc (hl)
        jr nz,.contest_ready
        dec (hl)
.contest_ready:
        ; READY for about a second with the clock stopped, as the arcade.
        ld a,(0xc89b)
        ld b,a
        ld a,(0xc89a)
        cp b
        jr nc,.contest
        ld hl,(0xfc9e)
        ld (0xc889),hl
        jr .frame
.contest:
        call update_clock
        call update_contest
.frame:
        call draw
        call display_wait_command
.wait_end:
        di                      ; no interrupt between the blank and the page (music)
        in a,(0x65)
        bit 6,a
        jr nz,.wait_end
.wait_start:
        in a,(0x65)
        bit 6,a
        jr z,.wait_start
        ld a,18
        out (0x64),a
        ld a,(0xc886)
        out (0x63),a
        xor 1
        ld (0xc886),a
        ld hl,palette
        call display_first_palette
        ei
        ld a,(0xc885)
        inc a
        ld (0xc885),a
        jp loop
        define DISPLAY_STAGE_HELPERS
        include "psg_calls.asm"   ; music calls, out of the flow
; A seconds since phase began, carry if still waiting.
elapsed_seconds:
        ld b,a
        ld hl,0
        ld a,(0xc888)
        ld e,a
        ld d,0
.mult:
        add hl,de
        djnz .mult
        ex de,hl
        ld hl,(0xfc9e)
        ld bc,(0xc88d)
        or a
        sbc hl,bc
        or a
        sbc hl,de
        ret
; Player power 0..64 (the arcade bar): each press adds 8 (7 at 50 Hz) and
; every 4 frames it loses an eighth, so 10 presses per second hold about
; 44, as measured in MAME, and fast pressing fills the bar.
update_input:
        xor a                  ; GTTRIG 0: space
        call 0x00d8
        or a
        jr nz,.button
        ld a,1                 ; GTTRIG 1: joystick 1 button A
        call 0x00d8
.button:
        ld b,a
        ld a,(0xc884)
        ld c,a
        ld a,b
        ld (0xc884),a
        or a
        jr z,.decay
        ld a,c
        or a
        jr nz,.decay
        ld a,(0xc89f)
        ld b,a
        ld a,(0xc881)
        add a,b
        cp 65
        jr c,.save
        ld a,64
.save:
        ld (0xc881),a
.decay:
        ld a,(0xc885)
        and 3
        ret nz
        ld a,(0xc881)
        ld b,a
        add a,7
        rrca
        rrca
        rrca
        and 0x1f
        ld c,a
        ld a,b
        sub c
        ld (0xc881),a
        ret
; Arcade clock 0:SS.t; at zero the CPU wins.
update_clock:
        ld hl,(0xfc9e)
        ld de,(0xc889)
        or a
        sbc hl,de
        ld a,(0xc89e)
        ld e,a
        ld d,0
        sbc hl,de
        ret c
        ld hl,(0xc889)
        add hl,de
        ld (0xc889),hl
        ld a,(0xc89d)
        sub 1
        jr nc,.tenth
        ld hl,0xc887
        dec (hl)
        ld a,(hl)               ; S.9 shown: a warning below 6 s (Spectrum)
        inc a
        call psg_countdown
        ld a,9
.tenth:
        ld (0xc89d),a
        ld hl,0xc887
        or (hl)
        ret nz
        ld a,SFX_TIME_UP
        call psg_sfx
        ld a,2
        jp finish
; CPU power measured in MAME: 30..40 in the first second of the contest,
; 60 for about 2.3 s when the player pushes hard (56 or more), then 34..46.
; The hand moves by the power difference: (player - CPU) * 5 per 4 frames
; (6 at 50 Hz) over 3200 units from the centre, so without pressing the CPU
; wins in about 1.1 s and at 10 presses per second the player in about 10 s.
; Easier than the arcade (asked by the user, 11 November): the CPU pushes
; 22..34 at first, 48 during its surge and 26..38 after it (arcade 29, 60
; and 34).
update_contest:
        ld a,(0xc885)
        and 3
        ret nz
        ld a,(0xc885)
        rrca
        rrca
        rrca
        and 3
        add a,a
        add a,a
        ld c,a
        ld a,(0xc89b)
        add a,a
        ld b,a
        ld a,(0xc89a)
        cp b
        ld a,22
        jr c,.cpu_power
        ld a,(0xc89a)
        ld hl,0xc89c
        cp (hl)
        jr nc,.steady
        ld a,(0xc881)
        cp 56
        ld a,48
        jr nc,.cpu_store
.steady:
        ld a,26
.cpu_power:
        add a,c
.cpu_store:
        ld (0xc882),a
        ld b,a
        ld a,(0xc881)
        sub b
        ld e,a
        rla
        sbc a,a
        ld d,a
        ld a,(0xc8a0)
        ld b,a
        ld hl,(0xc898)
.mult:
        add hl,de
        djnz .mult
        bit 7,h
        jr nz,.cpu_win
        ld (0xc898),hl
        add hl,hl
        add hl,hl
        ld a,h
        ld (0xc883),a
        cp 100
        ret c
        ld a,1
        jp finish
.cpu_win:
        ld hl,0
        ld (0xc898),hl
        xor a
        ld (0xc883),a
        ld a,2
finish:
        ld (0xc88c),a
        ld a,2
        ld (0xc880),a
        ld a,15
        ld (0xc418),a
        xor a
        ld (0xc736),a
        ld a,(0xc88c)
        cp 1
        jr z,.player_bonus
        ld hl,4000
        ld (0xc895),hl
        ld a,3
        ld (0xc897),a
        jr .recorded
.player_bonus:
        call load_victory_screen
        ld a,3
        ld (0xc736),a
        ld hl,(0xc75c)
        ld de,4000
        add hl,de
        ld (0xc75c),hl
        ld a,(0xc75e)
        adc a,0
        ld (0xc75e),a
.recorded:
        ld hl,(0xfc9e)
        ld (0xc88d),hl
        ret
; Overwrite the intro's off-screen VRAM page with the complete victory
; image. The compressed bytes reside in this same code bank.
load_victory_screen:
        ld a,9                  ; bonus music (WINNER / LOSER)
        call psg_play
        di
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        ld a,1
        out (0x63),a
        ld hl,victory_rle
.next_run:
        ld b,(hl)
        inc hl
        ld a,b
        or a
        jr z,.done
        ld a,(hl)
        inc hl
.emit:
        out (0x60),a
        djnz .emit
        jr .next_run
.done:
        ei
        ret
result_tick:
        ld a,3
        call elapsed_seconds
        ret c
        jp finish_transition
; This standalone build stops on the result; the MegaROM replaces this hook.
finish_transition:
        ret

draw:
        ld hl,background
        call copy_command
        ld a,(0xc880)
        or a
        ld a,2
        jr z,.bg_y
        ld a,(0xc880)
        cp 2
        jr nz,.top_background
        ld a,(0xc88c)
        cp 1
        ld a,2
        jr z,.bg_y
.top_background:
        ld a,3
.bg_y:
        ld (0xc303),a
        ld a,(0xc886)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld a,(0xc880)
        or a
        jr nz,.overhead
        ; Front view: READY blinks.
        ld a,(0xc885)
        and 16
        ret nz
        ld hl,label_ready
        jp blit
.overhead:
        ; Arcade poses as opaque 128x86 patches over the overhead picture.
        cp 2
        jr nz,.pose
        ld a,(0xc88c)
        cp 2
        jr nz,.meters
        ld hl,patch_cpu_win
        jr .patch
.pose:
        ld a,(0xc883)
        cp 35
        ld hl,patch_losing
        jr c,.patch
        cp 66
        jr c,.meters
        ld hl,patch_winning
.patch:
        call blit_opaque
.meters:
        ; Power bars: the player's fills from the left, the CPU's from the right.
        ld hl,bar_background
        call copy_command
        ld a,(0xc886)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld a,150
        ld (0xc304),a
        ld hl,0xc300
        call command
        ld a,(0xc881)
        ld b,40
        call red_bar
        ld a,(0xc882)
        ld c,a
        ld a,214
        sub c
        ld b,a
        ld a,c
        call red_bar
        ; Clock 0:SS.t ("0:" and "." are in the picture).
        ld a,(0xc887)
        ld b,0
.tens:
        cp 10
        jr c,.number
        sub 10
        inc b
        jr .tens
.number:
        ld (0xc88f),a
        ld a,b
        ld b,120
        call digit
        ld a,(0xc88f)
        ld b,128
        call digit
        ld a,(0xc89d)
        ld b,144
        call digit
        call draw_score
        ld a,(0xc880)
        cp 2
        jr z,.result_labels
        ; READY, then START blinking for two seconds.
        ld a,(0xc89b)
        ld b,a
        ld a,(0xc89a)
        cp b
        ld hl,label_ready
        jp c,blit
        ld c,a
        ld a,b
        add a,a
        add a,b
        cp c
        ret c
        ret z
        ld a,(0xc885)
        and 8
        ret nz
        ld hl,label_start
        jp blit
.result_labels:
        ld hl,label_stop
        call blit
        ld a,1
        call elapsed_seconds
        ret c
        ld a,(0xc88c)
        cp 1
        ld hl,label_player_win
        jr z,.winner
        ld hl,label_cpu_win
.winner:
        jp blit
; A width, B x
red_bar:
        or a
        ret z
        ld (0xc308),a
        ld a,b
        ld (0xc304),a
        ld a,0xee
        ld (0xc310),a
        ld (0xc311),a
        ld hl,0xc300
        jp command
; HL = sx, sy (word), dx, dy, width, height. Patches are opaque, texts not.
blit_opaque:
        push hl
        ld hl,patch_template
        jr blit_common
blit:
        push hl
        ld hl,text_template
blit_common:
        call copy_command
        pop hl
        ld de,0xc300
        ldi
        inc de
        ldi
        ldi
        ldi
        inc de
        ldi
        ld a,(0xc886)
        ld (de),a
        inc de
        ldi
        inc de
        ldi
        ld hl,0xc300
        jp command
; Arcade graphics at VRAM y 980..1151 (tools/extract_step5_arcade.py).
patch_losing:   db 0
                dw 980
                db 58,71,128,86
patch_winning:  db 128
                dw 980
                db 53,72,128,86
patch_cpu_win:  db 0
                dw 1066
                db 54,70,128,86
label_ready:    db 128
                dw 1080
                db 104,80,40,8
label_start:    db 128
                dw 1088
                db 104,72,40,8
label_stop:     db 128
                dw 1096
                db 104,72,32,8
label_player_win: db 128
                dw 1104
                db 72,48,110,8
label_cpu_win:  db 128
                dw 1112
                db 88,48,72,8
; Single game score in the black band above the clock: red 1P at x 16 and
; the total left-aligned from x 40 in the clock digits, leading zeros hidden.
draw_score:
        ld hl,label_1p
        call blit
        ld hl,(0xc75c)
        ld a,(0xc75e)
        ld e,a                  ; E:HL = score
        ld ix,score_powers
        ld d,40
        ld c,0
.digit:
        ld b,0xff
.subtract:
        inc b
        ld a,l
        sub (ix+0)
        ld l,a
        ld a,h
        sbc a,(ix+1)
        ld h,a
        ld a,e
        sbc a,(ix+2)
        ld e,a
        jr nc,.subtract
        ld a,l
        add a,(ix+0)
        ld l,a
        ld a,h
        adc a,(ix+1)
        ld h,a
        ld a,e
        adc a,(ix+2)
        ld e,a
        ld a,b
        or c
        ld c,a
        jr z,.hidden
        push bc
        push de
        push hl
        push ix
        ld a,b
        ld b,d
        ld c,6
        call digit_at
        pop ix
        pop hl
        pop de
        pop bc
        ld a,d
        add a,8
        ld d,a
.hidden:
        inc ix
        inc ix
        inc ix
        ld a,(ix+0)
        or a
        jr nz,.digit
        ld a,l
        ld b,d
        ld c,6
        jr digit_at
score_powers:
        db 0xa0,0x86,0x01, 0x10,0x27,0x00, 0xe8,0x03,0x00
        db 0x64,0x00,0x00, 0x0a,0x00,0x00, 0
label_1p:       db 128
                dw 1120
                db 16,8,16,10

; A digit, B dest x (digit: y 26, the clock; digit_at: y = C).
digit:
        ld c,26
digit_at:
        ld (0xc893),a
        ld a,b
        ld (0xc894),a
        ld a,(0xc893)
        add a,a
        add a,a
        add a,a
        add a,128
        ld (0xc893),a
        push bc
        ld hl,digit_template
        call copy_command
        pop bc
        ld a,c
        ld (0xc306),a
        ld a,(0xc893)
        ld (0xc300),a
        ld a,(0xc894)
        ld (0xc304),a
        ld a,(0xc886)
        ld (0xc307),a
        ld hl,0xc300
        jp command
copy_command:
        ld de,0xc300
        ld bc,21
        ldir
        ret
upload:
        ld bc,0x0060
        otir
        dec d
        jr nz,upload
        ret
command:
.wait:
        in a,(0x65)
        rrca
        jr c,.wait
        ld a,32
        out (0x64),a
        ld bc,21*256+0x63
        otir
        ret
background:
        dw 0,512,0,0,256,212
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
patch_template:
        dw 0,0,0,0,128,86
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
bar_background:
        dw 0,0,40,200,64,7
        db 0,0x0c,0xff,0xff,0x99,0x99,0,0,0x20
text_template:
        dw 0,0,0,0,8,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
digit_template:
        dw 128,1066,0,26,8,13
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
regs:   db 0x81,0,0x42,0
settings: db 0,0,0,0,0,0,0,0
palette: incbin "../build/step5/palette.bin"
victory_rle: incbin "../build/step5/victory-rle.bin"
        assert $ <= 0x8000
        ds 0x8000-$,0xff
        incbin "../build/step5/front.bin"
        incbin "../build/step5/struggle.bin"
        incbin "../build/step5/atlas.bin"
