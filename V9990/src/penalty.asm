; Penalty (chin-ups), as in the arcade (doc/referencia-penalizacion.md).
; Offered once per game when a step is lost by a small margin. Input:
; f201 chin-ups (5..10), f202 the step lost (1..6; 0 = standalone test).
; Arcade timing runs in ticks of 1/60 s from the BIOS JIFFY at 50 or 60 Hz.
; Space or joystick button 1 pull up. The instructor portrait, then the bar
; with the clock (0:20.0); success shows the event map and enters the next
; step without bonus, failure ends the game (cartridge title).
;
; RAM: f200-f206 are shared with the hooks of the steps (see src/demo_b1.asm),
; f270-f29f belong to this module, f2a0 holds the exit trampoline (f210-f26f:
; pen_try of src/demo_b1.asm, which must survive the penalty).
PEN_BASE equ 0                 ; first bank; tools/build_penalty_integrated.py
PEN_USED equ 0xf200
PEN_COUNT equ 0xf201
PEN_STEP equ 0xf202
JIFFY equ 0xfc9e
LAST equ 0xf270                ; last JIFFY (word)
ACC equ 0xf272                 ; ticks owed, in fifths of a tick
PAGE equ 0xf273                ; hidden page (0/1)
TIME equ 0xf274                ; ticks in the current phase (word)
PHASE equ 0xf276               ; 0 intro, 1 play, 2 made it, 3 blew it, 4 portrait
FORCE equ 0xf278               ; arcade 0x0965 (word)
HEIGHT equ 0xf27a              ; arcade 0x0a68 (word, 8.8)
LOWER equ 0xf27c               ; 1 while coming down after a chin-up
BUTTON equ 0xf27d              ; trigger state of the previous loop
EDGE equ 0xf27e                ; new press waiting for the next tick
SECONDS equ 0xf27f
TENTHS equ 0xf280
SUBTICK equ 0xf281
JOEX equ 0xf282
JOEPOSE equ 0xf283
STICK equ 0xf284
TRAMP equ 0xf2a0
RANK_BANK equ 0 ; ending bank of the final mission (Makefile, integrated build)

        org 0x4000
        db "AB"
        dw init
        dw 0,0,0
        jp game_over_entry     ; a step lost without penalty
        ds 3,0
init:
        di
        call psg_stop          ; silence previous step before long asset uploads
        di                     ; preserve the loader interrupt contract
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
        if PEN_BASE == 0
        ld a,5                 ; standalone test: five chin-ups
        ld (PEN_COUNT),a
        xor a
        ld (PEN_STEP),a
        endif
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
        call black_palette
        ld a,4
        ld (PHASE),a
        ; Instructor at y 512 (later the scene), patches at y 1024.
        ld de,0x0100
        ld hl,PEN_PORTRAIT_ADDR
        ld a,PEN_PORTRAIT_BANK+PEN_BASE
        call unpack
        ld de,0x0200
        ld hl,PEN_STICK_ADDR
        ld a,PEN_STICK_BANK+PEN_BASE
        call unpack
        ld de,0x0238
        ld hl,PEN_MOUTH_ADDR
        ld a,PEN_MOUTH_BANK+PEN_BASE
        call unpack
        ld hl,portrait_copy
        call blit
        ld hl,portrait_palette
        call set_palette
        call wait_cmd
        ld a,8
        out (0x64),a
        ld a,0xc2              ; display on
        out (0x63),a
        ld a,ARC_SERGEANT      ; restore the arcade sergeant theme (22h)
        call psg_arcade
        ei
        call reset_clock
        ; About 9.7 s: the stick taps every 32 ticks; the instructor talks
        ; between ticks 100 and 250 (mouth shapes from y 1136).
.portrait:
        call ticks
        ld hl,(TIME)
        ld de,580
        or a
        sbc hl,de
        jp nc,.portrait_done
        ld hl,(TIME)
        ld a,l
        srl h
        rr a
        srl h
        rr a
        srl h
        rr a
        srl h
        rr a
        srl h
        rr a                   ; TIME / 32
        and 1
        ld b,a
        ld a,(TIME)
        cp 40
        jr nc,.stick_ready
        ld a,(TIME+1)
        or a
        jr nz,.stick_ready
        ld b,0
.stick_ready:
        ; Mouth: shapes 0 (shut), 1, 2 every 8 ticks while talking.
        ld c,0
        ld hl,(TIME)
        ld de,100
        or a
        sbc hl,de
        jr c,.mouth_ready
        ld de,150
        or a
        sbc hl,de
        jr nc,.mouth_ready
        add hl,de
        ld a,l
        rrca
        rrca
        rrca
        and 3
        cp 3
        jr nz,.mouth_shape
        ld a,1
.mouth_shape:
        ld c,a
.mouth_ready:
        ld a,b
        add a,a
        add a,a
        or c
        ld hl,STICK
        cp (hl)
        jp z,.portrait
        ld (hl),a
        ; Begin the portrait update at a fresh V9990 vertical blank to avoid
        ; showing the restore and overlays at unrelated scan positions.
.portrait_wait_end:
        in a,(0x65)
        bit 6,a
        jr nz,.portrait_wait_end
.portrait_wait_start:
        in a,(0x65)
        bit 6,a
        jr z,.portrait_wait_start
        ld hl,portrait_restore
        call blit
        ld a,(STICK)
        and 4
        ld hl,portrait_stick
        call nz,blit
        ld a,(STICK)
        and 3
        jp z,.portrait
        dec a
        ld hl,portrait_mouth
        call copy_template
        jr z,.mouth_first
        ld hl,1188
        ld (0xc302),hl
.mouth_first:
        ld hl,0xc300
        call command
        jp .portrait
.portrait_done:
        di
        call psg_stop          ; silence before the next long upload
        di                     ; retain loader interrupt ownership
        call black_palette
        ; Scene source at y 512, poses and texts at y 768.
        ld de,0x0100
        ld hl,PEN_SCENE_ADDR
        ld a,PEN_SCENE_BANK+PEN_BASE
        call unpack
        ld de,0x0180
        ld hl,PEN_SPRITES_ADDR
        ld a,PEN_SPRITES_BANK+PEN_BASE
        call unpack
        xor a
        ld (PAGE),a
        call scene_copy
        ld a,1
        ld (PAGE),a
        call scene_copy
        ld hl,scene_palette
        call set_palette
        xor a
        ld (PHASE),a
        ld (LOWER),a
        ld (EDGE),a
        ld (BUTTON),a
        ld a,14                ; JOE standing
        ld (JOEPOSE),a
        ld hl,0
        ld (FORCE),hl
        ld (HEIGHT),hl
        ld a,104
        ld (JOEX),a
        ld a,20
        ld (SECONDS),a
        xor a
        ld (TENTHS),a
        ld (SUBTICK),a
        ld a,ARC_CHIN_UPS       ; the chin-ups' music of the arcade (2Bh)
        call psg_arcade
        ei
        call reset_clock
loop:
        call read_button
        call ticks
        call draw
        ld a,(PHASE)
        cp 2
        jr c,loop
        ld hl,(TIME)
        ld a,h
        cp 2                   ; 512 ticks after the end of the chin-ups
        jr c,loop
        call psg_stop          ; the chin-ups' music ends with the screen
        ld a,(PHASE)
        cp 2
        jp z,made_it
        jp game_over

; Wait for the next JIFFY and run the arcade ticks it owes: 6/5 per JIFFY
; at 50 Hz, one at 60 Hz.
ticks:
        halt
        ld hl,(JIFFY)
        ld de,(LAST)
        ld (LAST),hl
        or a
        sbc hl,de
        ld a,l
        or a
        ret z
        cp 8
        jr c,.owed
        ld a,8
.owed:
        ld b,a
        ld a,(0x002b)
        rlca
        ld c,5
        jr nc,.rate
        ld c,6
.rate:
        ld a,(ACC)
.add:
        add a,c
        djnz .add
.run:
        cp 5
        jr c,.done
        sub 5
        push af
        call tick
        pop af
        jr .run
.done:
        ld (ACC),a
        ret

        define DISPLAY_STAGE_HELPERS
        include "psg_calls.asm"   ; music calls, out of the flow
reset_clock:
        ld hl,(JIFFY)
        ld (LAST),hl
        ld hl,0
        ld (TIME),hl
        xor a
        ld (ACC),a
        ld (STICK),a
        ret

read_button:
        xor a
        call 0x00d8            ; GTTRIG 0: space
        push af                ; (GTTRIG does not keep B)
        ld a,1
        call 0x00d8            ; joystick 1, button A
        pop bc
        or b
        ld hl,BUTTON
        ld b,(hl)
        ld (hl),a
        or a
        ret z
        ld a,b
        or a
        ret nz
        ld a,1
        ld (EDGE),a
        ret

; One arcade tick (1/60 s).
tick:
        ld hl,(TIME)
        inc hl
        ld (TIME),hl
        ld a,(PHASE)
        cp 4
        ret nc                 ; instructor portrait: time only
        or a
        jr nz,.not_intro
        ; The clock starts 217 ticks after the scene; NICK takes the bar
        ; with the crouch (from 225) and the jump (from 241); presses count
        ; from 257, as in the arcade.
        ld de,257
        or a
        sbc hl,de
        ret c
        ld a,1
        ld (PHASE),a
        xor a
        ld (EDGE),a
        ld hl,0
        ld (TIME),hl
        ret
.not_intro:
        cp 1
        jp nz,joe_tick
        call clock_tick
        call joe_tick
        ; Force: each new press adds 0x0700 unless it would pass 0x4f00;
        ; then it loses 0xc0 + 4 * (high byte / 8), never below zero.
        ld hl,(FORCE)
        ld a,(EDGE)
        or a
        jr z,.decay
        xor a
        ld (EDGE),a
        ld de,0x0700
        add hl,de
        ld de,0x4f01
        or a
        sbc hl,de
        add hl,de
        jr c,.pressed
        ld hl,(FORCE)
.pressed:
.decay:
        ld a,h
        rrca
        rrca
        rrca
        and 0x1f
        add a,a
        add a,a
        add a,0xc0
        ld e,a
        ld a,0
        adc a,0
        ld d,a
        or a
        sbc hl,de
        jr nc,.force_ready
        ld hl,0
.force_ready:
        ld (FORCE),hl
        ld a,(LOWER)
        or a
        jr nz,.lowering
        ld a,h
        or a
        jr z,.fall
        ; Rising: + 1.0, + the pose term, + the force term.
        ld b,a
        ld a,(HEIGHT+1)
        ld c,0
        cp 0x10
        jr c,.pose_term
        inc c
        cp 0x28
        jr c,.pose_term
        inc c
        cp 0x30
        jr c,.pose_term
        inc c
        cp 0x38
        jr c,.pose_term
        inc c
        cp 0x3b
        jr c,.pose_term
        inc c
.pose_term:
        ld hl,pose_terms
        ld e,c
        ld d,0
        add hl,de
        ld a,(hl)
        ld l,a
        add a,a
        sbc a,a
        ld h,a
        inc h                  ; + 1.0
        ld a,b
        ld c,4
        cp 8
        jr c,.force_term
        dec c
        cp 16
        jr c,.force_term
        dec c
        cp 24
        jr c,.force_term
        dec c
        cp 32
        jr c,.force_term
        dec c
.force_term:
        ld a,c
        ld de,force_terms
        add a,e
        ld e,a
        ld a,(de)
        ld e,a
        add a,a
        sbc a,a
        ld d,a
        add hl,de
        ld de,(HEIGHT)
        add hl,de
        ld (HEIGHT),hl
        ld a,h
        cp 0x3f
        ret c
        ld hl,0x3f00
        ld (HEIGHT),hl
        ld a,1
        ld (LOWER),a
        ret
.fall:
        ld hl,(HEIGHT)
        ld de,0x0180
        or a
        sbc hl,de
        jr nc,.height
        ld hl,0
.height:
        ld (HEIGHT),hl
        ret
.lowering:
        ld hl,(HEIGHT)
        ld de,0x0180
        or a
        sbc hl,de
        ld (HEIGHT),hl
        ld a,h
        cp 0x0a
        ret nc
        xor a
        ld (LOWER),a
        ld hl,PEN_COUNT
        dec (hl)
        ret nz
        ld hl,0
        ld (HEIGHT),hl
        ld (TIME),hl
        ld a,2
        ld (PHASE),a
        ret

; 0:20.0, one tenth every 6 ticks; at 0:00.0 the penalty is lost.
clock_tick:
        ld hl,SUBTICK
        inc (hl)
        ld a,(hl)
        cp 6
        ret c
        ld (hl),0
        ld hl,TENTHS
        ld a,(hl)
        dec (hl)
        or a
        jr nz,.check
        ld (hl),9
        ld hl,SECONDS
        dec (hl)
.check:
        ld a,(SECONDS)
        ld hl,TENTHS
        or (hl)
        ret nz
        ld a,3
        ld (PHASE),a
        ld hl,0
        ld (TIME),hl
        ret

; JOE takes a break: idle at x 104, walks to 87, rests and walks back
; (cycle of 800 ticks, walking 60 ticks each way).
joe_tick:
        ld a,(PHASE)
        cp 1
        ret nz
        ld hl,(TIME)
        ld a,h
        and 3
        ld h,a                 ; TIME mod 1024
        ld de,400
        or a
        sbc hl,de
        jr c,.idle_right
        ld de,60
        sbc hl,de
        jr c,.walk_left
        ld de,280
        sbc hl,de
        jr c,.idle_left
        ld de,60
        sbc hl,de
        jr c,.walk_right
        jr .idle_right2
.walk_left:
        add hl,de              ; 0..59
        ld a,l
        call .walk_x
        neg
        add a,104
        ld (JOEX),a
        ld a,l
        call .walk_frame
        add a,16
        ld (JOEPOSE),a
        ret
.walk_right:
        add hl,de
        ld a,l
        call .walk_x
        add a,87
        ld (JOEX),a
        ld a,l
        call .walk_frame
        add a,19
        ld (JOEPOSE),a
        ret
.idle_left:
        ld a,87
        jr .idle
.idle_right2:
.idle_right:
        ld a,104
.idle:
        ld (JOEX),a
        ld a,(TIME)
        rlca
        rlca
        and 1                  ; joe / joe2 every 64 ticks
        add a,14
        ld (JOEPOSE),a
        ret
.walk_x:                       ; A = 0..59 -> A/4 + A/16, 0..17
        srl a
        srl a
        ld b,a
        srl a
        srl a
        add a,b
        ret
.walk_frame:                   ; three frames of 10 ticks
        ld b,0
.frame:
        sub 10
        jr c,.frame_done
        inc b
        jr .frame
.frame_done:
        ld a,b
.mod3:
        cp 3
        ret c
        sub 3
        jr .mod3

; Compose the hidden page and show it.
draw:
        call wait_cmd
        ld hl,restore_template
        call copy_template
        ld a,(PAGE)
        ld (0xc307),a
        call command_hl
        ld hl,restore_clock
        call copy_template
        ld a,(PAGE)
        ld (0xc307),a
        call command_hl
        ; JOE, then NICK in front.
        ld a,(JOEPOSE)
        ld b,a
        ld a,(JOEX)
        ld c,a
        ld a,b
        call draw_pose
        call nick_pose
        ld c,48
        call draw_pose
        call draw_texts
        call draw_clock
        call draw_count
        call draw_power
        call wait_cmd
show_page:                     ; as Step 7: flip at the V9990 vertical blank
        di                      ; no interrupt between the blank and the page (music)
        in a,(0x65)
        bit 6,a
        jr nz,show_page
.blank:
        in a,(0x65)
        bit 6,a
        jr z,.blank
        ld a,18
        out (0x64),a
        ld a,(PAGE)
        out (0x63),a
        xor 1
        ld (PAGE),a
        ei
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ret

; A = NICK's pose for this phase and moment.
nick_pose:
        ld a,(PHASE)
        or a
        jr nz,.playing
        ld hl,(TIME)
        ld de,225
        or a
        sbc hl,de
        ld a,0
        ret c
        ld de,16
        sbc hl,de
        ld a,1
        ret c
        ld a,2
        ret
.playing:
        cp 1
        jr nz,.ended
        ld a,(HEIGHT+1)
        ld b,a
        ld a,(LOWER)
        or a
        jr z,.rising
        ld a,b
        cp 0x2c
        ld a,7
        ret nc
        ld a,8
        ret
.rising:
        ld a,b
        cp 0x10
        ld a,3
        ret c
        ld a,b
        cp 0x28
        ld a,4
        ret c
        ld a,b
        cp 0x38
        ld a,5
        ret c
        ld a,6
        ret
.ended:
        cp 2
        ld hl,(TIME)
        jr nz,.fell
        ; Made it: standing, then the two arcade poses.
        ld de,300
        or a
        sbc hl,de
        ld a,0
        ret c
        ld de,30
        sbc hl,de
        ld a,9
        ret c
        ld a,10
        ret
.fell:
        ld de,30
        or a
        sbc hl,de
        ld a,11
        ret c
        ld de,30
        sbc hl,de
        ld a,12
        ret c
        ld a,13
        ret

; A = pose (pen_poses), C = screen x (NICK and JOE).
draw_pose:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        ld de,pen_poses
        add hl,de
        push hl
        ld hl,pose_template
        call copy_template
        pop hl
        ld a,(hl)
        ld (0xc300),a
        inc hl
        ld a,(hl)
        add a,0               ; atlas y 768 + 0/64/128
        ld (0xc302),a
        ld a,3
        ld (0xc303),a
        inc hl
        inc hl
        ld a,c
        ld (0xc304),a
        ld a,(hl)
        ld (0xc306),a
        ld a,(PAGE)
        ld (0xc307),a
        jp command_hl

; Texts: during the intro PLAYER 1 / (NICK), then TAKE A BREAK / (JOE)
; typed one character every 4 ticks; at the end PLAYER 1 / (NICK) and YOU,
; white or red, its last letter blinking.
draw_texts:
        ld a,(PHASE)
        or a
        jr nz,.not_intro
        ld hl,(TIME)
        call typed
        ld hl,label_player
        call label
        ld hl,(TIME)
        ld de,100
        or a
        sbc hl,de
        ret c
        call typed
        ld hl,label_break
        jp label
.not_intro:
        cp 1
        jr nz,.result
        ld hl,(TIME)
        ld de,160
        add hl,de
        call typed
        ld hl,label_break
        jp label
.result:
        ld hl,(TIME)
        ld de,60
        or a
        sbc hl,de
        ret c
        call typed
        ld hl,label_player
        call label
        ld hl,(TIME)
        ld de,124
        or a
        sbc hl,de
        ret c
        ld b,32                ; display all of YOU without partial-width blinking
.you:
        ld a,(PHASE)
        cp 2
        ld hl,label_you
        jr z,.you_colour
        ld hl,label_you_red
.you_colour:
        ld a,b
        jp label

; HL ticks -> A width in pixels, one 8-pixel character every 4 ticks.
typed:
        ld a,h
        or a
        ld a,255
        ret nz
        ld a,l
        and 0xfc
        add a,a
        ret nc
        ld a,255
        ret

; HL = label (sx, sy word, dx, dy, w, h), A = maximum width.
label:
        push af
        push hl
        ld hl,pose_template
        call copy_template
        pop hl
        pop bc
        ld a,(hl)
        ld (0xc300),a
        inc hl
        ld a,(hl)
        ld (0xc302),a
        inc hl
        ld a,(hl)
        ld (0xc303),a
        inc hl
        ld a,(hl)
        ld (0xc304),a
        inc hl
        ld a,(hl)
        ld (0xc306),a
        inc hl
        ld a,(hl)
        cp b
        jr c,.width
        ld a,b
.width:
        or a
        ret z
        ld (0xc308),a
        inc hl
        ld a,(hl)
        ld (0xc30a),a
        ld a,(PAGE)
        ld (0xc307),a
        jp command_hl

; 0:SS.t at x 56, y 26; red below six seconds.
draw_clock:
        ld a,(PHASE)
        or a
        ret z
        ld a,(SECONDS)
        cp 6
        ld c,0
        jr nc,.white
        ld c,96
.white:
        ld b,56
        xor a
        call clock_glyph
        ld a,10
        call clock_glyph
        ld a,(SECONDS)
        ld d,0
.tens:
        cp 10
        jr c,.ones
        sub 10
        inc d
        jr .tens
.ones:
        push af
        ld a,d
        call clock_glyph
        pop af
        call clock_glyph
        ld a,11
        call clock_glyph
        ld a,(TENTHS)
; A glyph (10 ':', 11 '.'), B screen x (advanced by 8), C colour offset.
clock_glyph:
        push bc
        add a,a
        add a,a
        add a,a
        add a,c
        push af
        ld hl,glyph_template
        call copy_template
        pop af
        pop bc
        ld (0xc300),a
        ld a,b
        ld (0xc304),a
        add a,8
        ld b,a
        ld a,(PAGE)
        ld (0xc307),a
        push bc
        call command_hl
        pop bc
        ret

; Two-digit count at x 56, y 191 (8x8 digits at y 992).
draw_count:
        ld a,(PEN_COUNT)
        ld d,0
.tens:
        cp 10
        jr c,.ones
        sub 10
        inc d
        jr .tens
.ones:
        push af
        ld a,d
        ld b,56
        call .digit
        pop af
        ld b,64
.digit:
        add a,a
        add a,a
        add a,a
        push af
        ld hl,digit_template
        call copy_template
        pop af
        ld (0xc300),a
        ld a,b
        ld (0xc304),a
        ld a,(PAGE)
        ld (0xc307),a
        jp command_hl

; POWER bar (x 48, y 201, 64x6): red as high as NICK has pulled himself.
draw_power:
        ld a,(HEIGHT+1)
        ld b,a
        ld a,(PHASE)
        cp 1
        ret nz
        ld a,b
        or a
        ret z
        ld hl,power_template
        call copy_template
        ld a,b
        inc a
        ld (0xc308),a
        ld a,(PAGE)
        ld (0xc307),a
        jp command_hl

; Hide the page being built: copy the scene into page PAGE.
scene_copy:
        ld hl,scene_template
        call copy_template
        ld a,(PAGE)
        ld (0xc307),a
        call command_hl
        jp wait_cmd

; The penalty is passed: event map (as after the step), then the next step
; without bonus.
made_it:
        di
        call black_palette
        ld a,(PEN_STEP)
        or a
        jp z,init              ; standalone test
        ld a,PEN_BASE
        or a
        jp z,init
        ; Event map: base image in page 0, squares of the completed steps in
        ; page 1, the two pages blink for five seconds.
        xor a
        call map_screen
        ld a,1
        call map_screen
        ld a,(PEN_STEP)
        ld b,a
        ld hl,map_rows
.square:
        push bc
        push hl
        ld a,(hl)
        push af
        ld hl,map_square
        call copy_template
        pop af
        ld (0xc306),a
        ld a,1
        ld (0xc307),a
        call command_hl
        call wait_cmd
        pop hl
        pop bc
        inc hl
        djnz .square
        ld hl,map_palette
        call set_palette
        ei
        call reset_clock
.map:
        call ticks
        ld a,18
        out (0x64),a
        ld a,(TIME)
        rrca
        rrca
        rrca
        rrca
        and 1
        out (0x63),a
        ld hl,(TIME)
        ld de,300
        or a
        sbc hl,de
        jr c,.map
        di
        call display_map_off
        ; Next step, as its own transition leaves it: no bonus seconds or
        ; points, the 50/60 Hz rate in c734.
        ld a,(0x002b)
        rlca
        ld a,60
        jr nc,.rate
        ld a,50
.rate:
        ld (0xc734),a
        xor a
        ld (0xc736),a
        ld (0xc43f),a
        ld (0xc413),a
        ld hl,0
        ld (0xc440),hl
        ld (0xc414),hl
        ld a,35
        ld (0xc417),a
        ld a,(PEN_STEP)
        dec a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,next_steps
        add hl,de
        ld de,TRAMP+1
        ldi                    ; bank
        inc hl
        inc de
        inc de
        inc de
        inc de
        ldi                    ; address
        ldi
        ld hl,TRAMP
        ld (hl),0x3e           ; ld a,bank
        inc hl
        inc hl
        ld (hl),0x32           ; ld (0x6000),a
        inc hl
        ld (hl),0x00
        inc hl
        ld (hl),0x60
        inc hl
        ld (hl),0xc3           ; jp entry
        ld sp,0xf000
        jp TRAMP

; A step lost with no penalty due or left: the same GAME OVER.
game_over_entry:
        di
        ld sp,0xf000
        ; Silence the lost step's music first, as init does: with interrupts
        ; off during the uploads its last notes would hold as a beep.
        call psg_stop
        di
        ld a,4
        ld (PHASE),a           ; ticks only count time
        call display_off        ; R8 is latched per frame: no flash
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
        call black_palette
        ld de,0x0180
        ld hl,PEN_SPRITES_ADDR
        ld a,PEN_SPRITES_BANK+PEN_BASE
        call unpack
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
; The penalty is lost: GAME OVER, then the RANKING table and the title.
game_over:
        di
        call psg_stop          ; the penalty's music must not hold either
        di
        call black_palette
        xor a
        ld (PAGE),a
        ld hl,clear_template
        call blit
        ld hl,gameover_template
        call blit
        ld a,18
        out (0x64),a
        xor a
        out (0x63),a
        ld hl,scene_palette
        call set_palette
        ld a,ARC_GAME_OVER     ; GAME OVER: the arcade's 2Ah
        call psg_arcade
        ei
        call reset_clock
.wait:
        call ticks
        ld hl,(TIME)
        ld de,240
        or a
        sbc hl,de
        jr c,.wait
        ; Then until its music ends (src/psg_arcade.asm), at most 10 s in all.
        ld hl,(TIME)
        ld de,600
        or a
        sbc hl,de
        jr nc,.over
        ld a,(0xfda1)
        cp PSG_CALL_HOOK
        jr nz,.over             ; no music installed
        ld a,(PSG_CALL_ARC_ON)
        or a
        jr nz,.wait
.over:
        di
        call black_palette
        ld a,(PEN_STEP)
        or a
        jp z,init
        ld a,PEN_BASE
        or a
        jp z,init
        ld hl,title_trampoline
        ld de,TRAMP
        ld bc,title_trampoline_end-title_trampoline
        ldir
        ld sp,0xf000
        jp TRAMP
; The RANKING table (src/ranking.asm, 0x4010), which then shows the title.
title_trampoline:
        ld a,RANK_BANK
        ld (0x6000),a
        jp 0x4010
title_trampoline_end:

; A = page: the event map (picture 62 of image_table, tools/build_image_pack.py,
; in the game cartridge) into it.
map_screen:
        rrca
        ld e,a                 ; VRAM address = page * 0x8000
        ld d,0
        ld hl,image_table
.find:
        ld a,(hl)
        cp 62
        jr z,.found
        ld bc,7
        add hl,bc
        jr .find
.found:
        inc hl
        ld a,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld h,(hl)
        ld l,c
        jp unpack

; A = first bank, HL = address in page 2, DE = VRAM address bits 8..18
; (y * 128 / 256): unpack a stream into consecutive VRAM bytes. Control
; 1..127 literals, 129..255 repeat, 128 next bank, 0 end.
unpack:
        ld (0x7000),a
        ld b,a
        xor a
        out (0x64),a
        out (0x63),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
.next:
        call .byte
        or a
        ret z
        cp 128
        jr c,.literal
        jr z,.next_bank        ; 128: the stream goes on in the next bank
        sub 128
        ld c,a
        call .byte
.run:
        out (0x60),a
        dec c
        jr nz,.run
        jr .next
.literal:
        ld c,a
.copy:
        call .byte
        out (0x60),a
        dec c
        jr nz,.copy
        jr .next
.next_bank:
        ld hl,0x8000
        inc b
        ld a,b
        ld (0x7000),a
        jr .next
.byte:
        ld a,(hl)
        inc hl
        bit 6,h                ; 0xc000: continue in the next bank
        ret z
        ld h,0x80
        inc b
        push af
        ld a,b
        ld (0x7000),a
        pop af
        ret

black_palette:
        call wait_retrace       ; between two frames, never mid-frame
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ld b,48
.zero:
        out (0x61),a
        djnz .zero
        ret
set_palette:
        call wait_retrace       ; between two frames, never mid-frame
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ld bc,0x3061
        otir
        ret

copy_template:                 ; keeps BC
        push bc
        ld de,0xc300
        ld bc,21
        ldir
        pop bc
        ret
blit:
        call copy_template
command_hl:
        ld hl,0xc300
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
wait_cmd:
        in a,(0x65)
        rrca
        jr c,wait_cmd
        ret

; Command blocks: sx, sy, dx, dy, nx, ny; arg, logic op, mask, colour, cmd.
portrait_copy:
        dw 0,512,0,0,256,212
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
portrait_restore:
        dw 68,580,68,68,104,122
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
portrait_stick:
        dw 0,1024,0,78,256,112
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
portrait_mouth:
        dw 0,1136,0,68,256,52
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
scene_template:
        dw 0,512,0,0,256,212
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
restore_template:
        dw 0,598,0,86,256,126
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
restore_clock:
        dw 56,538,56,26,48,13
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
pose_template:
        dw 0,768,0,0,32,64
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
glyph_template:
        dw 0,1000,0,26,8,13
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
digit_template:
        dw 0,992,0,191,8,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
power_template:
        dw 0,0,48,201,64,6
        db 0,0x0c,0xff,0xff,POWER_RED,POWER_RED,0,0,0x20
clear_template:
        dw 0,0,0,0,256,212
        db 0,0x0c,0xff,0xff,0,0,0,0,0x20
gameover_template:
        dw 168,968,88,88,72,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
map_square:                     ; 16x29, one every 30 lines
        dw 0,0,16,0,16,29
        db 0,0x0c,0xff,0xff,0x99,0x99,0,0,0x20
; Squares of steps 1..6 on the event map (page 1), from the transitions.
map_rows:
        db 182,152,122,92,62,32   ; the map's squares (tools/extract_progress_maps.py)
; Labels: atlas sx, sy (word), screen dx, dy, width, height.
label_player:   db 0,0xc0,3,32,88,72,16
label_break:    db 72,0xc0,3,128,88,96,16
label_you:      db 168,0xc0,3,16,120,32,8
label_you_red:  db 200,0xc0,3,16,120,32,8
; Next step after the penalty: bank, (unused), entry; indexed by step - 1.
next_steps:
        db 0,0
        dw 0x400d              ; Step 2 (shoot_start)
        db 95,0
        dw 0x4010              ; Step 3
        db 77,0
        dw 0x4010              ; Step 4
        db 85,0
        dw 0x4010              ; Step 5
        db 0,0
        dw 0                   ; Step 5 is never lost
        db 55,0
        dw 0x4010              ; Step 7
pose_terms: db 0,-16,-32,-88,-100,-104
        align 8
force_terms: db 32,0,-64,-96,-128
regs:   db 0x81,0,0x42,0
settings: db 0,0,0,0,0,0,0,0
scene_palette: incbin "../build/penalty/scene-palette.bin"
portrait_palette: incbin "../build/penalty/portrait-palette.bin"
map_palette: incbin "../build/demo/map-palette.bin"
        include "../build/penalty/penalty.inc"
        assert $ <= 0x5800
; Picture table of the game cartridge (event map, map_screen).
        include "../build/demo/image-table.inc"
        ds 0x5800-$,0xff
        incbin "../build/penalty/data.bin"
