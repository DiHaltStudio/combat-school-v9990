; Firing Range I prototype. World and atlas are B1 bitmaps in banks 74–76.
; c430/c431 crosshair, c432 targets, c433 trigger latch, c434 hits,
; c435 seconds, c436 JIFFY, c438 page, c439 wave, c43a state,
; c43b target y, c43f bonus seconds, c440 bonus points, c45f hits before
; the current wave (for the arcade's points by hit order).
SHOOT_TRACER_PHASE equ 0xc48a    ; 0: inactive, 7/5/3/1: path fractions
SHOOT_TRACER_AIM equ 0xc48b      ; x, y at trigger time
shoot_start:
        xor a
        ld (0xc45b),a          ; first shooting range
        jr shoot_start_common
; Entry from the Step 5 map, with the current cartridge already mapped.
step6_entry:
        ld a,1
        ld (0xc45b),a
        ld a,(0xc736)
        add a,24               ; arcade: 0:27.0 with the +3 s of Step 5
        ld (0xc417),a
        ld a,(0xc734)
        ld (0xc0dd),a
shoot_start_common:
        di
        call display_off        ; off from the next frame on
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        ; Restore field outside the display pages, at y=768.
        xor a
        out (0x64),a
        out (0x63),a
        ld a,0x80
        out (0x63),a
        ld a,1
        out (0x63),a
        ld a,74
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload_blocks
        ld a,75
        ld (0x7000),a
        ld hl,0x8000
        ld d,42
        call upload_blocks
        ; Transparent atlas at y=512, 64 rows: rows 32-63 hold the near
        ; target and the PLAYER 1 / (NICK) labels.
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        ld a,1
        out (0x63),a
        ld a,76
        ld (0x7000),a
        ld hl,0x8000
        ld d,32
        call upload_blocks
        ; The arcade's explosion on a hit target (bank 76 padding) at y=640.
        xor a
        out (0x64),a
        out (0x63),a
        ld a,0x40
        out (0x63),a
        ld a,1
        out (0x63),a
        ld d,16
        call upload_blocks
        ; Five 48x64 player poses at y=576: three aiming poses captured from
        ; the arcade video, then standing up and arm raised (Step 2 result).
        ld a,93
        ld (0x7000),a
        ld hl,0x8000
        xor a
        ld (0xc45a),a
.pose_upload_frame:
        ld a,(0xc45a)
        ld e,a
        add a,a
        add a,e
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0x20
        ld b,64
.pose_upload_row:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,1
        out (0x63),a
        ld bc,0x1860
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,.pose_upload_next
        inc d
.pose_upload_next:
        pop bc
        djnz .pose_upload_row
        ld a,(0xc45a)
        inc a
        ld (0xc45a),a
        cp 5
        jr nz,.pose_upload_frame
        xor a
        ld (0xc433),a
        ld (0xc434),a
        ld (0xc438),a
        ld (0xc439),a
        ld (0xc43f),a
        ld (0xc440),a
        ld (0xc441),a
        ld (0xc454),a
        ld (0xc45e),a          ; instructor penalty inactive
        ld (SHOOT_TRACER_PHASE),a
        ld hl,0xc470           ; no explosion (shoot_explode)
        ld b,20
.no_explosion:
        ld (hl),a
        inc hl
        djnz .no_explosion
        ld a,120
        ld (0xc430),a
        ld a,80
        ld (0xc431),a
        ld a,(0xfc9e)
        or a
        jr nz,.seed_ready
        ld a,0x5d
.seed_ready:
        ld (0xc449),a
        call shoot_new_wave
        ld a,(0xc417)
        ld (0xc435),a
        ld a,1
        ld (0xc43a),a
        ld a,(0xc45b)
        or a
        ld a,4
        jr z,.stage_ready
        ld a,17
.stage_ready:
        ld (0xc418),a
        ld hl,(0xfc9e)
        ld (0xc436),hl
        ld a,3                  ; shooting range music (Steps 2 and 6)
        call psg_play
        ei
shoot_loop:
        ld a,(0xc43a)
        cp 1
        jr z,.playing
        cp 2
        jr nz,.failed
        call shoot_qualified_tick
        jr .render
.failed:
        call shoot_result_input
        jr .render
.playing:
        call shoot_clock
        call shoot_wave_clock
        call shoot_input
.render:
        call shoot_draw
        jp shoot_loop

; Step 6 keeps its result for 3 s. Step 2 lasts 5.5 s as in the arcade:
; label, standing up, raised arm and PLAYER 1 / YOU MADE IT.
shoot_qualified_tick:
        ld hl,(0xfc9e)
        ld de,(0xc452)
        or a
        sbc hl,de
        push hl
        ld a,(0xc0dd)
        ld l,a
        ld h,0
        ld d,h
        ld e,l
        add hl,hl
        add hl,de
        add hl,de
        add hl,de
        srl e
        add hl,de
        ex de,hl
        pop hl
        or a
        sbc hl,de
        ret c
        ld a,(0xc45b)
        or a
        jp nz,step6_bonus_screen
        jp shoot_progress_screens

; Show the shooting bonus and the map with the first two tests completed.
shoot_progress_screens:
        ld a,9                  ; bonus music
        call psg_play
        call display_off        ; off from the next frame on
        ld hl,progress_palette
        call intro_set_palette
        ld a,15
        out (0x64),a
        ld a,PROGRESS_BLACK
        out (0x63),a
        xor a
        ld (0xc0b6),a
        ld a,60
        call intro_frame
        ld a,(0xc43f)
        call progress_marker
        ld a,5
        ld (0xc418),a
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld hl,(0xfc9e)
        ld (0xc452),hl
.wait_bonus:
        ld hl,(0xfc9e)
        ld de,(0xc452)
        or a
        sbc hl,de
        ld a,(0xc0dd)
        add a,a
        add a,a
        cp l
        jr nc,.wait_bonus
        call psg_wait_song      ; the bonus music ends first
        call psg_stop           ; the map is silent
        call display_off        ; off from the next frame on
        ld hl,map_palette
        call intro_set_palette
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        inc a
        ld (0xc0b6),a
        ld a,62
        call intro_frame
        ld a,1
        call progress_map_light
        xor a
        ld (0xc0b6),a
        ld a,62
        call intro_frame
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld a,6
        ld (0xc418),a
        ld hl,(0xfc9e)
        ld (0xc452),hl
.blink_map:
        halt
        ld a,(0xfc9e)
        and 16
        rrca
        rrca
        rrca
        rrca
        ld b,a
        ld a,18
        out (0x64),a
        ld a,b
        out (0x63),a
        ld hl,(0xfc9e)
        ld de,(0xc452)
        or a
        sbc hl,de
        push hl
        ld a,(0xc0dd)
        ld e,a
        ld d,0
        ld hl,0
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        ex de,hl
        pop hl
        or a
        sbc hl,de
        jr c,.blink_map
        ; Switching page 1 replaces this code immediately. Execute the
        ; mapper change and jump from RAM so the switch is atomic.
        di
        call display_map_off
        ld hl,step3_trampoline
        ld de,0xc800
        ld bc,step3_trampoline_end-step3_trampoline
        ldir
        jp 0xc800
step3_trampoline:
        ld a,95
        ld (0x6000),a
        jp 0x4010
step3_trampoline_end:

; Add the earned points exactly once, then display the selected Step 6 row.
step6_bonus_screen:
        ld a,9                  ; bonus music
        call psg_play
        ld hl,(0xc75c)
        ld de,(0xc440)
        add hl,de
        ld (0xc75c),hl
        ld a,(0xc75e)
        adc a,0
        ld (0xc75e),a
        call display_off        ; off from the next frame on
        ld hl,progress_palette
        call intro_set_palette
        ld a,15
        out (0x64),a
        ld a,PROGRESS_BLACK
        out (0x63),a
        xor a
        ld (0xc0b6),a
        ld a,51
        call intro_frame
        ld a,(0xc43f)
        call progress_marker
        ld a,19
        ld (0xc418),a
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld hl,(0xfc9e)
        ld (0xc452),hl
.wait:
        halt
        ld hl,(0xfc9e)
        ld de,(0xc452)
        or a
        sbc hl,de
        ld a,(0xc0dd)
        add a,a
        add a,a
        ld e,a
        ld d,0
        or a
        sbc hl,de
        jr c,.wait

; The two recorded poses share one background; only the seated cadet's arm
; rectangle is replaced. Both patches fit in the second image bank's padding.
        call display_off        ; off from the next frame on
        ld hl,step6_interlude_palette
        call intro_set_palette
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        ld (0xc0b6),a
        ld a,53
        call intro_frame
        ld a,20
        ld (0xc418),a
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld hl,(0xfc9e)
        ld (0xc452),hl
        xor a
        ld (0xc460),a
.interlude:
        halt
        ld hl,(0xfc9e)
        ld de,(0xc452)
        or a
        sbc hl,de
        push hl
        ld a,l
        and 32
        ld b,a
        ld a,(0xc460)
        cp b
        jr z,.same_pose
        ld a,b
        ld (0xc460),a
        call step6_interlude_patch
.same_pose:
        pop hl
        ld a,(0xc0dd)
        ld e,a
        ld d,0
        add hl,hl              ; compare 2*elapsed with 10*refresh rate
        push hl
        ld hl,0
        add hl,de
        add hl,hl
        add hl,hl
        add hl,de
        add hl,hl
        ex de,hl
        pop hl
        or a
        sbc hl,de
        jr c,.interlude
        jp step6_progress_map

; A = pose (0/1): from the interlude picture's extra data (intro_frame).
step6_interlude_patch:
        ld ix,(0xc0c9)
        or a
        jr z,.source_ready
        ld de,1248             ; second pose
        add ix,de
.source_ready:
        ld hl,13592            ; x=48, y=106, 128 bytes per line (the arcade's hand)
        ld d,52
.patch_row:
        xor a
        out (0x64),a
        ld a,l
        out (0x63),a
        ld a,h
        out (0x63),a
        xor a
        out (0x63),a
        ld b,24
.patch_byte:
        ld a,(ix+0)
        out (0x60),a
        inc ix
        djnz .patch_byte
        ld bc,128
        add hl,bc
        dec d
        jr nz,.patch_row
        ret
step6_interlude_palette: incbin "../build/demo/step6-interlude-palette.bin"

; Show the six-step map, then enter the combat bank via a RAM trampoline.
step6_progress_map:
        call psg_wait_song      ; the bonus music ends first
        call psg_stop           ; the map is silent
        call display_off        ; off from the next frame on
        ld hl,map_palette
        call intro_set_palette
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        inc a
        ld (0xc0b6),a
        ld a,62
        call intro_frame
        ld a,1
        call progress_map_light
        call wait_cmd
        ld a,122
        ld (0xc306),a
        ld a,29                 ; the map's squares: 29 lines
        ld (0xc30a),a
        ld hl,0xc300
        call command
        call wait_cmd
        ld a,92
        ld (0xc306),a
        ld hl,0xc300
        call command
        call wait_cmd
        ld a,62
        ld (0xc306),a
        ld hl,0xc300
        call command
        call wait_cmd
        ld a,32
        ld (0xc306),a
        ld hl,0xc300
        call command
        call wait_cmd
        xor a
        ld (0xc0b6),a
        ld a,62
        call intro_frame
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld a,18
        ld (0xc418),a
        ld hl,(0xfc9e)
        ld (0xc452),hl
.map_wait:
        halt
        ld a,(0xfc9e)
        and 16
        rrca
        rrca
        rrca
        rrca
        ld b,a
        ld a,18
        out (0x64),a
        ld a,b
        out (0x63),a
        ld hl,(0xfc9e)
        ld de,(0xc452)
        or a
        sbc hl,de
        ld a,(0xc0dd)
        add a,a
        add a,a                ; four seconds at the current video rate
        ld e,a
        ld d,0
        or a
        sbc hl,de
        jr c,.map_wait
        di
        call display_map_off
        ld hl,step7_trampoline
        ld de,0xca80
        ld bc,step7_trampoline_end-step7_trampoline
        ldir
        jp 0xca80
step7_trampoline:
        ld a,55
        ld (0x6000),a
        jp 0x4010
step7_trampoline_end:

shoot_result_input:
        ; Steps 2 and 6: 1-4 hits short of 44 / 32 -> 7-10 chin-ups.
        ld a,(0xc45b)
        or a
        ld b,2
        ld c,44
        jr z,.quota
        ld b,6
        ld c,32
.quota:
        ld a,(0xc434)
        ld e,a
        ld a,c
        sub e
        jr c,.no_penalty
        jr z,.no_penalty
        cp 5
        jr nc,.no_penalty
        add a,6
        jr .penalty
.no_penalty:
        xor a
.penalty:
        call 0xf210            ; pen_try (src/demo_b1.asm)
        ret c
        xor a
        call 0x00d8
        or a
        jr nz,.pressed
        ld a,1
        call 0x00d8
.pressed:
        ld b,a
        ld a,(0xc433)
        ld c,a
        ld a,b
        ld (0xc433),a
        or a
        ret z
        ld a,c
        or a
        ret nz
        jp init

shoot_clock:
        ld hl,(0xfc9e)
        ld de,(0xc436)
        or a
        sbc hl,de
        ld a,h
        or a
        jr nz,.tick
        ld a,(0xc0dd)
        cp l
        ret nc
.tick:
        ld hl,(0xc436)
        ld a,(0xc0dd)
        ld e,a
        ld d,0
        add hl,de
        ld (0xc436),hl
        ld a,(0xc435)
        or a
        ret z
        dec a
        ld (0xc435),a
        call psg_countdown      ; the last seconds and the end (Spectrum)
        ret nz
        ld a,(0xc45b)
        or a
        ld a,44
        jr z,.qualify_limit
        ld a,32               ; two complete rows of 16; inferred from video
.qualify_limit:
        ld b,a
        ld a,(0xc434)
        cp b
        ld a,3
        jr c,.result
        ld a,2
.result:
        ld (0xc43a),a
        ld hl,(0xfc9e)
        ld (0xc452),hl
        ld a,(0xc434)
        ld b,a
        ld a,(0xc45b)
        or a
        ld a,b
        jr z,.first_range_bonus
        ; Step 6 has 32 qualifying targets. Each additional hit gives one
        ; bonus bracket, up to five (33..37+), as in the arcade result table.
        ld b,0
        cp 33
        jr c,.bonus
        inc b
        cp 34
        jr c,.bonus
        inc b
        cp 35
        jr c,.bonus
        inc b
        cp 36
        jr c,.bonus
        inc b
        cp 37
        jr c,.bonus
        inc b
        jr .bonus
.first_range_bonus:
        ld b,0
        cp 48
        jr c,.bonus
        inc b
        cp 52
        jr c,.bonus
        inc b
        cp 56
        jr c,.bonus
        inc b
        cp 60
        jr c,.bonus
        inc b
        cp 68
        jr c,.bonus
        inc b
.bonus:
        ld a,b
        ld (0xc43f),a
        add a,a
        ld e,a
        ld d,0
        ld hl,progress_points
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (0xc440),de
        ; Step 2: the game score so far, Step 1 and Step 2 bonuses (Step 6
        ; adds its bonus in step6_bonus_screen).
        ld a,(0xc45b)
        or a
        ret nz
        ld hl,(0xc414)
        add hl,de
        ld (0xc75c),hl
        ld a,0
        adc a,0
        ld (0xc75e),a
        ret

shoot_input:
        ld a,(0xc45e)
        or a
        jp nz,.fire             ; frozen aim, but keep the trigger latch updated
        xor a
        call 0x00d5              ; cursor keys
        or a
        jr nz,.direction
        ld a,1
        call 0x00d5              ; joystick 1
.direction:
        cp 9
        jp nc,.fire
        add a,a
        ld e,a
        ld d,0
        ld hl,shoot_directions
        add hl,de
        ld a,(0xc45b)
        or a
        jr nz,.board_sight
        ; Step 2, measured in MAME: 3.25 px per 60 Hz frame (195 px/s) on
        ; both axes, from the jiffies elapsed since the previous update.
        push hl
        ld hl,(0xfc9e)
        ld de,(0xc469)
        ld (0xc469),hl
        ld a,l
        sub e
        cp 5
        jr c,.elapsed
        ld a,4
.elapsed:
        ld b,a
        ld a,(0xc0dd)
        cp 50
        ld c,13               ; quarter pixels per jiffy at 60 Hz
        jr nz,.rate
        ld c,16               ; and at 50 Hz
.rate:
        ld a,(0xc46b)
        inc b
        dec b
        jr z,.step
.speed:
        add a,c
        djnz .speed
.step:
        ld d,a
        and 3
        ld (0xc46b),a
        ld a,d
        rrca
        rrca
        and 0x3f
        ld d,a
        pop hl
        ld c,(hl)
        ld a,(0xc430)
        call shoot_axis
        cp 241
        jr nc,.keep_x
        ld (0xc430),a
.keep_x:
        inc hl
        ld c,(hl)
        ld a,(0xc431)
        call shoot_axis
        cp 24
        jr c,.fire
        cp 141
        jr nc,.fire
        ld (0xc431),a
        jr .fire
.board_sight:
        ; Step 6, as the arcade: the sight stays on the row of boards and
        ; jumps 40 px to the next board every 0.2 s while a side is held.
        ld a,50
        ld (0xc431),a
        ld a,(hl)
        or a
        jr z,.fire
        ld c,a
        ld hl,(0xfc9e)
        ld de,(0xc46c)
        or a
        sbc hl,de
        ld a,h
        or a
        jr nz,.jump
        ld a,2
        call tenths_to_jiffies
        cp l
        jr nc,.fire
.jump:
        ld d,40
        ld a,(0xc430)
        call shoot_axis
        cp 40
        jr c,.fire
        cp 201
        jr nc,.fire
        ld (0xc430),a
        ld hl,(0xfc9e)
        ld (0xc46c),hl
.fire:
        xor a
        call 0x00d8
        or a
        jr nz,.pressed
        ld a,1
        call 0x00d8
.pressed:
        ld b,a
        ld a,(0xc433)
        ld c,a
        ld a,b
        ld (0xc433),a
        ld a,(0xc45e)
        or a
        ret nz                ; do not fire until the next target group
        ld a,b
        or a
        ret z
        ld a,c
        or a
        ret nz
        ld hl,(0xc430)
        ld (SHOOT_TRACER_AIM),hl
        ld a,7
        ld (SHOOT_TRACER_PHASE),a
        jp shoot_hit            ; only a hit sounds (SFX_HIT)

shoot_directions:
        db 0,0, 0,-1, 1,-1, 1,0, 1,1, 0,1, -1,1, -1,0, -1,-1
; A = coordinate, C = direction (-1, 0, 1), D = distance.
shoot_axis:
        dec c
        jr z,.plus
        inc c
        ret z
        sub d
        ret
.plus:
        add a,d
        ret

shoot_hit:
        ld a,(0xc45b)
        or a
        jr z,.range_ready
        call step6_phase
        cp 2
        ret nz
.range_ready:
        ld hl,0xc44a
        ld b,5
        ld c,1
.target:
        ld a,(0xc432)
        and c
        jr z,.next
        ld a,(0xc430)
        sub (hl)
        add a,11
        cp 23
        jr nc,.next
        ld a,(0xc431)
        ld d,a
        ld a,(0xc43b)
        ld e,a
        ld a,d
        sub e
        add a,11
        cp 23
        jr nc,.next
        ld a,(0xc45b)
        or a
        jr z,.ordinary_target
        ld a,(0xc45d)
        and c
        jr z,.ordinary_target
        ; The current group keeps its normal expiry; only the aim is locked.
        ld a,1
        ld (0xc45e),a
        ret
.ordinary_target:
        call shoot_explode
        ld a,SFX_HIT            ; a target hit (Spectrum)
        call psg_sfx
        ld a,(0xc432)
        xor c
        ld (0xc432),a
        call shoot_points
        ld a,(0xc434)
        cp 99
        jr nc,.check_wave
        inc a
        ld (0xc434),a
.check_wave:
        ld a,(0xc432)
        or a
        ret nz
        ld a,(0xc45b)
        or a
        ret nz
        jp shoot_new_wave
.next:
        inc hl
        sla c
        djnz .target
        ret
; Each group has two, three or four adjacent targets at varying positions.
shoot_new_wave:
        ld a,(0xc434)
        ld (0xc45f),a          ; hits before this wave (shoot_points)
        xor a
        ld (0xc45e),a          ; a new group releases the instructor penalty
        ld a,(0xc449)
        srl a                   ; LFSR x^8+x^6+x^5+x^4+1: all 255 values (RRCA
        jr nc,.random_ready     ; had seeds that repeated the same group)
        xor 0xb8
.random_ready:
        ld (0xc449),a
        and 3
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        add a,32
        ld hl,0xc44a
        ld (hl),a
        add a,24
        inc hl
        ld (hl),a
        add a,24
        inc hl
        ld (hl),a
        add a,24
        inc hl
        ld (hl),a
        add a,24
        inc hl
        ld (hl),a
        ld a,(0xc45b)
        or a
        jr z,.positions_ready
        ; Step 6: five boards at x 40..200, as in the arcade.
        ld a,40
        ld hl,0xc44a
        ld b,5
.step6_position:
        ld (hl),a
        add a,40
        inc hl
        djnz .step6_position
.positions_ready:
        ld a,(0xc449)
        rrca
        rrca
        and 3
        ld e,a
        ld d,0
        ld hl,shoot_wave_masks
        add hl,de
        ld a,(hl)
        ld b,a
        ld a,(0xc45b)
        or a
        ld a,b
        jr z,.mask_ready
        ld a,31               ; five positions as seen in the recording
.mask_ready:
        ld (0xc432),a
        xor a
        ld (0xc45d),a
        ld a,(0xc45b)
        or a
        jr z,.instructor_ready
        ld a,(0xc449)
        and 7
        cp 5
        jr c,.instructor_index
        sub 5
.instructor_index:
        ld e,a
        ld d,0
        ld hl,shoot_instructor_masks
        add hl,de
        ld a,(hl)
        ld b,a
        ld a,(0xc449)
        bit 5,a
        ld a,b
        jr z,.instructor_mask_ready
        add a,a
        cp 32
        jr c,.second_instructor
        ld a,1
.second_instructor:
        or b
.instructor_mask_ready:
        ld (0xc45d),a
.instructor_ready:
        ld a,(0xc449)
        rrca
        rrca
        rrca
        rrca
        and 3
        ld e,a
        ld d,0
        ld hl,shoot_wave_y
        add hl,de
        ld a,(hl)
        ld b,a
        ld a,(0xc45b)
        or a
        ld a,b
        jr z,.wave_y
        ld a,50               ; Step 6: one row of boards
.wave_y:
        ld (0xc43b),a
        ld hl,(0xfc9e)
        ld (0xc450),hl
        ret
shoot_wave_clock:
        ld hl,(0xfc9e)
        ld de,(0xc450)
        or a
        sbc hl,de
        ld a,h
        or a
        jr nz,.next_wave
        ld a,(0xc45b)
        or a
        jr z,.range1
        ld a,23               ; Step 6 boards: up, down, 2.3 s per group
        call tenths_to_jiffies
        cp l
        ret nc
        jr .next_wave
.range1:
        ld a,(0xc0dd)
        ld b,a
        add a,a
        add a,b
        cp l
        ret nc
.next_wave:
        jp shoot_new_wave
; Step 6 board state from the time since the group began, as in the arcade:
; A=1 rising (0.1 s), 2 standing until 1.5 s, 1 falling, 0 lying.
step6_phase:
        ld hl,(0xfc9e)
        ld de,(0xc450)
        or a
        sbc hl,de
        ld a,h
        or a
        ld a,0
        ret nz
        ld a,1
        call tenths_to_jiffies
        cp l
        ld a,1
        ret nc
        ld a,15
        call tenths_to_jiffies
        cp l
        ld a,2
        ret nc
        ld a,16
        call tenths_to_jiffies
        cp l
        ld a,1
        ret nc
        xor a
        ret
; Five arcade boards (atlas x=128.., y=544): ring or red soldier (c45d), in
; the current state; a hit board lies down.
step6_targets:
        call step6_phase
        ld (0xc462),a
        ld hl,0xc44a
        ld b,5
        ld c,1
.slot:
        push bc
        push hl
        ld a,(hl)
        ld (0xc467),a          ; destination x
        ld a,(0xc462)
        ld e,a
        cp 2
        jr nz,.state
        ld a,(0xc432)
        and c
        jr nz,.state
        ld e,0
.state:
        ld a,2
        sub e
        add a,a
        ld e,a
        ld a,(0xc45d)
        and c
        jr z,.ring
        inc e
.ring:
        ld a,e
        add a,a
        add a,a
        add a,a
        add a,a
        add a,128
        ld (0xc463),a          ; atlas x
        ld hl,0xc463
        call shoot_blit_at
        pop hl
        pop bc
        inc hl
        sla c
        djnz .slot
        ret
; Board entry at c463: atlas x, row 32, 16x32, destination x (c467), y 50.
shoot_blit_at:
        ld a,32
        ld (0xc464),a
        ld (0xc466),a
        ld a,16
        ld (0xc465),a
        ld a,50
        ld (0xc468),a
        jp shoot_blit
shoot_wave_masks: db 3,7,15,7
shoot_instructor_masks: db 1,2,4,8,16
shoot_wave_y: db 48,72,96,112

; Step 2 qualified result, from the arcade at 60 Hz: A=0 before 2.2 s,
; 1 standing up, 2 arm raised from 2.5 s, 3 centred text from 2.8 s.
shoot_goal_phase:
        ld hl,(0xfc9e)
        ld de,(0xc452)
        or a
        sbc hl,de
        ld a,h
        or a
        ld a,3
        ret nz
        ld e,0
        ld a,22
        call tenths_to_jiffies
        cp l
        jr nc,.done
        inc e
        ld a,25
        call tenths_to_jiffies
        cp l
        jr nc,.done
        inc e
        ld a,28
        call tenths_to_jiffies
        cp l
        jr nc,.done
        inc e
.done:
        ld a,e
        ret

; HL -> atlas x, atlas row (y=512+row), width, height, destination x, y.
shoot_blit:
        push hl
        ld hl,shoot_sprite_template
        ld de,0xc300
        ld bc,21
        ldir
        pop hl
        ld a,(hl)
        ld (0xc300),a
        inc hl
        ld a,(hl)
        ld (0xc302),a
        inc hl
        ld a,(hl)
        ld (0xc308),a
        inc hl
        ld a,(hl)
        ld (0xc30a),a
        inc hl
        ld a,(hl)
        ld (0xc304),a
        inc hl
        ld a,(hl)
        ld (0xc306),a
        ld a,(0xc438)
        ld (0xc307),a
        ld hl,0xc300
        jp command
; Arcade positions moved to the ROM field (ROM y = arcade y - 14).
shoot_made_it_top:    db 32,16,88,10,25,34
shoot_made_it_centre: db 32,16,88,10,25,104
shoot_blew_it_centre: db 32,48,88,10,25,104
shoot_player_label:   db 16,32,64,10,32,71
shoot_nick_label:     db 80,32,48,10,40,82

shoot_draw:
        ld hl,shoot_background
        ld de,0xc300
        ld bc,21
        ldir
        ld a,(0xc438)
        ld (0xc307),a
        ld hl,0xc300
        call command
        call shoot_player_pose
        ; Step 2: targets and crosshair are gone once the time is up, as in
        ; the arcade's result.
        ld a,(0xc43a)
        cp 1
        jr nz,.targets_done
        ld a,(0xc45b)
        or a
        jr z,.draw_targets
        call step6_targets
        jr .crosshair
.draw_targets:
        ld hl,0xc44a
        ld b,5
        ld c,1
.targets:
        push bc
        push hl
        ld a,(0xc432)
        and c
        jr z,.skip_target
        ld d,(hl)
        ld a,(0xc43b)
        ld e,a
        xor a
        ld a,(0xc45d)
        and c
        ld a,0
        jr z,.draw_target
        ld a,128
.draw_target:
        call shoot_sprite
.skip_target:
        pop hl
        pop bc
        inc hl
        sla c
        djnz .targets
.crosshair:
        call shoot_explosions
        call shoot_tracer
        ld a,(0xc430)
        ld d,a
        ld a,(0xc431)
        ld e,a
        ld a,16
        call shoot_sprite
.targets_done:
        ; Two decimal digits for seconds and hits.
        ld a,(0xc435)
        ld d,64
        ld e,6
        call shoot_number
        xor a
        ld d,8
        ld e,180
        call shoot_number
        ld a,(0xc434)
        ld d,24
        ld e,180
        call shoot_number
        call shoot_score
        ld a,(0xc45b)
        or a
        jr z,.range1_grid
        call shoot_step6_grid
        jp .status
.range1_grid:
        ; Up to 44 small squares in two rows, copied from the transparent atlas.
        ld a,(0xc434)
        cp 22
        jr c,.first_row
        ld a,22
.first_row:
        ld d,8
        ld e,196
        call shoot_cells
        ld a,(0xc434)
        cp 22
        jr c,.status
        sub 22
        cp 22
        jr c,.second_row
        ld a,22
.second_row:
        ld d,8
        ld e,199
        call shoot_cells
.extra_rows:
        ld a,(0xc434)
        cp 44
        jr c,.status
        sub 44
        ld (0xc455),a
        ld e,202
.extra_loop:
        ld a,(0xc455)
        or a
        jr z,.status
        cp 22
        jr c,.extra_width
        ld a,22
.extra_width:
        ld (0xc456),a
        push de
        ld d,8
        call shoot_cells
        pop de
        ld a,(0xc455)
        ld b,a
        ld a,(0xc456)
        ld c,a
        ld a,b
        sub c
        ld (0xc455),a
        ld a,e
        add a,3
        ld e,a
        jr .extra_loop
.status:
        ld a,(0xc43a)
        cp 1
        jr nz,.result_status
        ; YOU MADE IT blinks top left once the quota is reached.
        ld a,(0xc45b)
        or a
        ld b,44
        jr z,.quota
        ld b,32
.quota:
        ld a,(0xc434)
        cp b
        jr c,.flip
        ld a,(0xfc9e)
        and 64
        jr z,.flip
        jr .made_it_top
.result_status:
        cp 2
        jr z,.qualified
        ; Lost (arcade): PLAYER 1 (NICK) / YOU BLEW IT in red, mid-field.
        ld hl,shoot_player_label
        call shoot_blit
        ld hl,shoot_nick_label
        call shoot_blit
        ld hl,shoot_blew_it_centre
        call shoot_blit
        jr .flip
.qualified:
        ; Qualified: the label stays top left, then the arcade's
        ; PLAYER 1 (NICK) / YOU MADE IT in the middle of the field.
        call shoot_goal_phase
        cp 3
        jr c,.made_it_top
        ld hl,shoot_player_label
        call shoot_blit
        ld hl,shoot_nick_label
        call shoot_blit
        ld hl,shoot_made_it_centre
        call shoot_blit
        jr .flip
.made_it_top:
        ld hl,shoot_made_it_top
        call shoot_blit
        jr .flip
.status_draw:
        ld d,112
        cp 32
        jr nz,.status_position
        ld d,84
.status_position:
        ld e,35
        call shoot_label
.flip:
        call wait_cmd
.wait_vblank_end:
        di                      ; no interrupt between the blank and the page (music)
        in a,(0x65)
        bit 6,a
        jr nz,.wait_vblank_end
.wait_vblank_start:
        in a,(0x65)
        bit 6,a
        jr z,.wait_vblank_start
        ld a,18
        out (0x64),a
        ld a,(0xc438)
        out (0x63),a
        xor 1
        ld (0xc438),a
        ld hl,shoot_palette
        call display_first_palette
        ei
        ret

; Step 6 shows 16 cells per row; surplus cells are drawn individually.
shoot_step6_grid:
        ld hl,shoot_grid_clear
        ld de,0xc300
        ld bc,21
        ldir
        ld a,(0xc438)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld a,(0xc434)
        ld (0xc455),a
        ld a,196
        ld (0xc461),a
.row:
        ld a,(0xc455)
        or a
        ret z
        cp 16
        jr c,.width
        ld a,16
.width:
        ld (0xc456),a
        ld d,8
        ld a,(0xc461)
        ld e,a
        ld a,(0xc456)
        call shoot_cells
        ld a,(0xc455)
        ld b,a
        ld a,(0xc456)
        ld c,a
        ld a,b
        sub c
        ld (0xc455),a
        ld a,(0xc461)
        add a,3
        ld (0xc461),a
        cp 212
        jr c,.row
        ret
shoot_grid_clear:
        dw 0,0,72,196,24,6
        db 0,0x0c,0xff,0xff,SHOOT_GROUND,SHOOT_GROUND,0,0,0x20   ; the field's ground (tools/build_shoot_assets.py)

; Keep the body/rifle in step with the cursor's horizontal direction. After
; passing Step 2 the shooter stands up (pose 3) and raises his arm (pose 4).
shoot_player_pose:
        ld a,(0xc43a)
        cp 2
        jr nz,.aim
        call shoot_goal_phase
        or a
        jr z,.aim
        cp 1
        ld a,3
        jr z,.selected
        ld a,4
        jr .selected
.aim:
        ld a,(0xc430)
        call shoot_aim_pose
.selected:
        ld (0xc45a),a
        ld b,a
        add a,a
        add a,b
        add a,a
        add a,a
        add a,a
        add a,a
        ld (0xc442),a
        ld hl,shoot_pose_template
        ld de,0xc300
        ld bc,21
        ldir
        ld a,(0xc442)
        ld (0xc300),a
        ld a,(0xc438)
        ld (0xc307),a
        ld hl,0xc300
        jp command

; A = sight x. Return the same pose index for the rifle and the shot origin.
shoot_aim_pose:
        cp 72
        jr c,.left
        cp 136
        ld a,1
        ret c
        inc a
        ret
.left:
        xor a
        ret

; Draw a cosmetic projectile on the back page. Hits still resolve at the
; trigger edge. Four frames show 1/8, 3/8, 5/8 and 7/8 of the path towards
; the original sight position.
shoot_tracer:
        ld a,(SHOOT_TRACER_PHASE)
        or a
        ret z
        ld b,a
        sub 2
        jr nc,.phase_ready
        xor a
.phase_ready:
        ld (SHOOT_TRACER_PHASE),a
        ld a,(SHOOT_TRACER_AIM)
        call shoot_aim_pose
        add a,a
        ld e,a
        ld d,0
        ld hl,shoot_muzzles
        add hl,de
        ld a,(SHOOT_TRACER_AIM)
        add a,6                 ; center a 5x5 dot on the sight center
        ld c,a
        ld a,(hl)
        call shoot_tracer_axis
        ld (0xc488),a
        inc hl
        ld a,(SHOOT_TRACER_AIM+1)
        add a,6
        ld c,a
        ld a,(hl)
        call shoot_tracer_axis
        ld (0xc489),a
        ld hl,shoot_tracer_atlas
        ld de,0xc484            ; reuse explosion blit descriptor after drawing it
        ld bc,4
        ldir
        ld hl,0xc484
        jp shoot_blit

; A = muzzle, C = aim, B = phase. Read the three bits of the
; fraction from right to left, averaging with the muzzle or aim each time.
shoot_tracer_axis:
        push bc
        ld d,a
        ld a,8
        sub b
        ld e,a
        ld b,3
        ld a,d
.fraction:
        srl e
        jr c,.toward_aim
        add a,d
        jr .average
.toward_aim:
        add a,c
.average:
        rra                     ; midpoint, including the carry from the sum
        djnz .fraction
        pop bc
        ret
shoot_muzzles:      db 59,136, 62,139, 84,139
shoot_tracer_atlas: db 202,0,5,5

; A=atlas x, D/E=destination. Default 16x16.
shoot_sprite:
        ld (0xc442),a
        ld a,d
        ld (0xc443),a
        ld a,e
        ld (0xc444),a
        ld hl,shoot_sprite_template
        ld de,0xc300
        ld bc,21
        ldir
        ld a,(0xc442)
        ld (0xc300),a
        ld a,(0xc443)
        ld (0xc304),a
        ld a,(0xc444)
        ld (0xc306),a
        ld a,(0xc438)
        ld (0xc307),a
        ld a,(0xc442)
        or a
        jr nz,.normal_height
        ; Arcade targets: the near one (16x32, atlas y=544) on the lower rows.
        ld a,(0xc444)
        cp 96
        ld a,24
        jr c,.target_height
        ld a,32
        ld (0xc302),a
.target_height:
        ld (0xc30a),a
.normal_height:
        ld hl,0xc300
        jp command

; The arcade's explosion on a hit target (Steps 2 and 6, tools/
; extract_target_explosion.py): fire, a cloud of smoke, the last puffs, 6, 6
; and 8 arcade frames. Per target slot at c470: active, JIFFY at the hit,
; x, y. HL -> the target's x (c44a + slot), B = 5 - slot; keeps BC, HL.
shoot_explode:
        push hl
        push bc
        ld d,(hl)
        ld a,(0xc43b)
        ld e,a
        ld a,5
        sub b
        add a,a
        add a,a
        ld l,a
        ld h,0
        ld bc,0xc470
        add hl,bc
        ld (hl),1
        inc hl
        ld a,(0xfc9e)
        ld (hl),a
        inc hl
        ld (hl),d
        inc hl
        ld (hl),e
        pop bc
        pop hl
        ret

; Draws the explosions under way (atlas row 128 = y 640): fire and cloud
; 32x32 at the target's x-8, y+2; the puffs 16x32 at x, y+2.
shoot_explosions:
        ld hl,0xc470
        ld b,5
.slot:
        ld a,(hl)
        or a
        jr z,.next
        push bc
        push hl
        inc hl
        ld a,(0xfc9e)
        sub (hl)
        ld c,a                  ; jiffies since the hit
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        add a,2
        ld (0xc489),a           ; destination y
        ld a,(0xc0dd)
        cp 50
        ld hl,shoot_explosion_times
        jr nz,.times
        inc hl
        inc hl
        inc hl
.times:
        ld a,c
        ld e,0                  ; fire: atlas x 0
        cp (hl)
        jr c,.wide
        inc hl
        ld e,32                 ; cloud: atlas x 32
        cp (hl)
        jr c,.wide
        inc hl
        cp (hl)
        jr c,.puffs
        pop hl
        ld (hl),0               ; over
        pop bc
        jr .next
.puffs:
        ld a,64
        ld (0xc484),a
        ld a,16
        ld (0xc486),a
        ld a,d
        jr .blit
.wide:
        ld a,e
        ld (0xc484),a
        ld a,32
        ld (0xc486),a
        ld a,d
        sub 8
        jr nc,.blit
        xor a
.blit:
        ld (0xc488),a           ; destination x
        ld a,128
        ld (0xc485),a
        ld a,32
        ld (0xc487),a
        ld hl,0xc484
        call shoot_blit
        pop hl
        pop bc
.next:
        inc hl
        inc hl
        inc hl
        inc hl
        djnz .slot
        ret
; Ends of fire, cloud and puffs in jiffies: 60 Hz (arcade frames), 50 Hz.
shoot_explosion_times:
        db 6,12,20
        db 5,10,17

; Arcade (Steps 2 and 6): each hit scores 100 times its order within the
; wave, 100..500. The arcade's special 1000/2000 boards are left out.
shoot_points:
        ld a,(0xc45f)
        ld b,a
        ld a,(0xc434)
        sub b
        inc a
        cp 6
        jr c,.order
        ld a,5
.order:
        ld hl,0
        ld de,100
.times:
        add hl,de
        dec a
        jr nz,.times
        ex de,hl
        jp add_score

; Single game score at the top right (the clock is at x 64): red 1P from
; the atlas (x 16, y 560) at x 152, the total from x 176 in atlas digits.
shoot_score:
        ld hl,shoot_sprite_template
        ld de,0xc300
        ld bc,21
        ldir
        ld a,16
        ld (0xc300),a
        ld (0xc308),a
        ld hl,560
        ld (0xc302),hl
        ld a,152
        ld (0xc304),a
        ld a,6
        ld (0xc306),a
        ld a,(0xc438)
        ld (0xc307),a
        ld a,10
        ld (0xc30a),a
        ld hl,0xc300
        call command
        ld d,176
        ld iy,shoot_score_digit
        jp score_digits
shoot_score_digit:
        ld b,a
        ld a,d
        ld (0xc446),a
        ld a,6
        ld (0xc447),a
        ld a,b
        jp shoot_digit

shoot_number:
        ld (0xc445),a
        ld a,d
        ld (0xc446),a
        ld a,e
        ld (0xc447),a
        ld a,(0xc445)
        ld b,0
.tens:
        cp 10
        jr c,.ready
        sub 10
        inc b
        jr .tens
.ready:
        ld (0xc448),a
        ld a,b
        call shoot_digit
        ld a,(0xc446)
        add a,8
        ld (0xc446),a
        ld a,(0xc448)
        jp shoot_digit
shoot_digit:
        add a,a
        add a,a
        add a,a
        add a,32
        ld (0xc442),a
        ld hl,shoot_sprite_template
        ld de,0xc300
        ld bc,21
        ldir
        ld a,(0xc442)
        ld (0xc300),a
        ld a,(0xc446)
        ld (0xc304),a
        ld a,(0xc447)
        ld (0xc306),a
        ld a,(0xc438)
        ld (0xc307),a
        ld a,8
        ld (0xc308),a
        ld a,10
        ld (0xc30a),a
        ld hl,0xc300
        jp command

; A=count, D/E=destination.
shoot_cells:
        or a
        ret z
        add a,a
        add a,a
        ld (0xc442),a
        ld a,d
        ld (0xc443),a
        ld a,e
        ld (0xc444),a
        ld hl,shoot_sprite_template
        ld de,0xc300
        ld bc,21
        ldir
        ld a,112
        ld (0xc300),a
        ld a,(0xc442)
        ld (0xc308),a
        ld a,2
        ld (0xc30a),a
        jr shoot_finish_small
shoot_label:
        ld (0xc442),a
        ld a,d
        ld (0xc443),a
        ld a,e
        ld (0xc444),a
        ld hl,shoot_sprite_template
        ld de,0xc300
        ld bc,21
        ldir
        ld a,(0xc442)
        ld (0xc300),a
        ld a,16
        ld (0xc302),a
        ld a,32
        ld b,a
        ld a,(0xc442)
        cp 32
        jr nz,.label_width
        ld b,88
.label_width:
        ld a,b
        ld (0xc308),a
        ld a,10
        ld (0xc30a),a
shoot_finish_small:
        ld a,(0xc443)
        ld (0xc304),a
        ld a,(0xc444)
        ld (0xc306),a
        ld a,(0xc438)
        ld (0xc307),a
        ld hl,0xc300
        jp command

shoot_background:
        dw 0,768,0,0,256,212
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
shoot_sprite_template:
        dw 0,512,0,0,16,16
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
shoot_pose_template:
        dw 0,576,40,130,48,64
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
