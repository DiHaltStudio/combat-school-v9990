; Assailant experiment. Two actor records approach from opposite sides;
; movement, attack and recovery remain approximations based on MAME.
; c850 spawn delay; c851 state (0 wait, 1 approach, 2 hit, 3 fall,
; 4 down, 5 removed); c852 world x; c854 phase timer; c855 cadence;
; c856 player health; c857 recovery; c858 kick latch; c85a enemy facing;
; c85c player world x; c85e absolute separation.
; Shared cooldowns must tick only once even when both actors are active.
mission_enemy_global_tick:
        ld hl,0xc820
        ld a,(hl)
        or a
        jr z,.flash_ready
        dec (hl)
.flash_ready:
        ld hl,0xc857
        ld a,(hl)
        or a
        jr z,.recovery_ready
        dec (hl)
.recovery_ready:
        ld hl,0xc823
        ld a,(hl)
        or a
        ret z
        dec (hl)
        ret

mission_enemy_tick:
        ld a,(0xc803)
        or a
        jr nz,.attack_latch_ready
        ld (0xc858),a
.attack_latch_ready:
        ld a,(0xc851)
        or a
        jr z,.waiting
        cp 1
        jr z,.approach
        cp 5
        ret nc
.fall_countdown:                ; every body goes after a while (frame time)
        ld hl,0xc854
        ld a,(hl)
        or a
        jr z,.next_fall_phase
        dec (hl)
        ret nz
.next_fall_phase:
        ld hl,0xc851
        inc (hl)
        ld a,(hl)
        cp 3
        ld a,32
        jr nz,.down_timer
        ld a,(0xc86f)
        cp 2
        ld a,32
        jr nz,.set_fall_timer
        ld a,14                 ; two brief orange kneeling poses
        jr .set_fall_timer
.down_timer:
        ld a,150                ; 2.5 s on the floor, then gone
.set_fall_timer:
        ld (0xc854),a
        ret
.waiting:
        ld a,(0xc856)
        or a
        ret z                   ; no new attackers after a fatal hit
        ld hl,0xc850
        ld a,(hl)
        or a
        jr z,.spawn
        dec (hl)
        ret nz
.spawn:
        ; Enter at the left or right edge of the current view.
        ld hl,(0xc840)
        ld a,(0xc86f)
        or a
        jr z,.spawn_position_ready
        ld de,192
        add hl,de
.spawn_position_ready:
        ld (0xc852),hl
        ld a,1
        ld (0xc851),a
        ld a,(0xc86f)
        ld (0xc85a),a
        ret
.approach:
        ld a,(0xc856)
        or a
        ret z
        ld a,(0xc823)           ; the captured arcade encounter pauses nearby actors
        or a
        ret nz
        ld a,(0xc801)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld (0xc85c),hl
        ex de,hl
        ld hl,(0xc852)
        or a
        sbc hl,de
        jr c,.enemy_left
        ld a,1                  ; enemy faces left toward player
        ld (0xc85a),a
        jr .distance_ready
.enemy_left:
        ld hl,(0xc85c)
        ld de,(0xc852)
        or a
        sbc hl,de
        xor a                   ; enemy faces right toward player
        ld (0xc85a),a
.distance_ready:
        ld (0xc85e),hl
        ld a,(0xc86f)
        cp 2
        call nc,mission_try_throw
        ld hl,(0xc85e)
        ld a,h
        or a
        jp nz,.move
        ld a,l
        cp 33                   ; arcade kick reaches 32 px (mame_mission_kick_reach.lua)
        jr c,.in_range
        ld a,(0xc8ac)
        or a
        jp z,.move
        ld a,l
        cp 76
        ret c                   ; launcher keeps its distance by the crates
        jp .move
.in_range:
        ; Assailants on the floor cannot reach the player on the overhead pipe.
        ld a,(0xc8dd)
        or a
        ret nz
        ; Ground attacks do not reach a player standing on the crate stack.
        ld a,(0xc8d4)
        or a
        ret nz
        ; The attack must face the target, intersect its range and be active.
        ld a,(0xc858)
        or a
        jr nz,.contact
        ld a,(0xc803)
        cp 5
        jr c,.contact
        cp 25
        jr nc,.contact
        ld a,(0xc809)
        xor 1
        ld b,a
        ld a,(0xc85a)
        cp b
        jr nz,.contact
        ld a,(0xc804)
        or a
        jr z,.hit
        ; A flying kick must actually be extended and within body height.
        ld a,(0xc803)
        cp 19
        jr c,.contact
        ld a,(0xc80a)
        cp 49
        jr nc,.contact
.hit:
        ld hl,(0xc852)
        ld a,96                 ; shared orange impact graphic
        call mission_start_impact
        ld a,1
        ld (0xc858),a
        ld a,2
        ld (0xc851),a
        ld a,(0xc86f)
        cp 2
        ld a,20
        jr nz,.hit_timer
        ld a,8
.hit_timer:
        ld (0xc854),a
        ; The recorded first enemy awards 500 points once on impact.
        ld hl,(0xc75c)
        ld de,500
        add hl,de
        ld (0xc75c),hl
        ld a,(0xc75e)
        adc a,0
        ld (0xc75e),a
        ret
.contact:
        ld hl,(0xc85e)
        ld a,l
        cp 19
        jr nc,.move
        ld a,(0xc80a)
        cp 33                   ; a high enough jump avoids a ground attack
        ret nc
        ld a,(0xc857)
        or a
        ret nz
        ; The observed ordinary assailant contact ends the mission in one hit.
        jp mission_player_hit
.move:
        ld a,(0xc9a4)
        or a
        ret nz                  ; fixed-position bottle attacker
        ; Roughly 1.25 pixels per update, measured in one arcade capture.
        ld hl,(0xc852)
        ld a,(0xc85a)
        or a
        jr nz,.move_left
        inc hl
        ld a,(0xc855)
        and 3
        jr nz,.save_position
        inc hl
        jr .save_position
.move_left:
        dec hl
        ld a,(0xc855)
        and 3
        jr nz,.save_position
        dec hl
.save_position:
        ld (0xc852),hl
        ld hl,0xc855
        inc (hl)
        ret

; Save the contact in world coordinates so the flash follows the scrolling.
; A selects the source tile and HL is the hit actor's 64px sprite origin.
mission_start_impact:
        push af
        ld a,SFX_BLOW           ; the blow lands (the fight's sound, Spectrum)
        call psg_sfx
        pop af
        ld (0xc821),a
        ld de,24
        add hl,de
        ld (0xc825),hl
        ld a,6
        ld (0xc820),a
        ret

mission_draw_impact:
        ld a,(0xc820)
        or a
        ret z
        ld hl,(0xc825)
        ld de,(0xc840)
        or a
        sbc hl,de
        ret c
        ld a,h
        or a
        ret nz
        ld a,l
        cp 241
        ret nc
        ld (0xc827),a
        ld hl,flash_template
        call copy_command
        ld a,(0xc821)
        ld (0xc300),a
        ld a,232                ; atlas y=1256 + 0, low byte
        ld (0xc302),a
        ld a,4
        ld (0xc303),a
        ld a,(0xc827)
        ld (0xc304),a
        ld hl,(0xc825)
        ld de,8
        add hl,de
        call mission_floor_at_world
        add a,128
        ld (0xc306),a
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        jp command

mission_draw_enemy:
        ld a,(0xc851)
        or a
        ret z
        cp 5
        ret nc
        xor a
        ld (0xc9a0),a          ; amount clipped at the left edge
        ld hl,(0xc852)
        ld de,(0xc840)
        or a
        sbc hl,de
        jr nc,.enemy_on_screen
        ; Keep the visible part when the actor enters from the left.
        ld hl,(0xc840)
        ld de,(0xc852)
        or a
        sbc hl,de
        ld a,h
        or a
        ret nz
        ld a,l
        cp 47                  ; 17px margin + 30px of artwork
        ret nc
        ld (0xc9a0),a
        xor a
        jr .enemy_position_ready
.enemy_on_screen:
        ld a,h
        or a
        ret nz
        ld a,l
        cp 193                  ; right-edge clipping remains conservative
        ret nc
.enemy_position_ready:
        ld (0xc85b),a
        ld hl,actor_template
        call copy_command
        ld a,(0xc85b)
        ld (0xc304),a
        ld hl,(0xc852)
        ld de,32
        add hl,de
        call mission_floor_at_world
        add a,104
        ld b,a
        ld a,(0xc9a4)
        or a
        ld a,b
        jr z,.ground_anchor_ready
        add a,6                 ; second-crate thrower: feet on the lower floor
.ground_anchor_ready:
        ld (0xc306),a
        ld a,(0xc802)
        ld (0xc307),a
        ld a,(0xc9a5)
        or a
        jr z,.normal_enemy_pose
        ld a,(0xc85a)
        or a
        ld a,0
        jr z,.bottle_pose_facing
        ld a,64
.bottle_pose_facing:
        ld (0xc300),a
        ld a,80                 ; captured pose at VRAM y=592
        ld (0xc302),a
        ld a,2
        ld (0xc303),a
        jp mission_enemy_command
.normal_enemy_pose:
        ld a,(0xc851)
        cp 4
        jp z,.down
        cp 3
        ld a,192
        jr z,.pose
        ld a,(0xc851)
        cp 2
        ld a,128
        jr z,.pose
        ld a,(0xc855)
        and 24
        cp 16
        jr nz,.walk_normal
        ld a,(0xc86f)
        cp 2
        jr nz,.walk_third
.walk_normal:
        ld a,(0xc855)
        and 8
        ld a,0
        jr z,.pose
        ld a,64
.pose:
        ld (0xc300),a
        ld a,(0xc86f)
        cp 2
        jr z,.orange_row
        ld a,128
        ld (0xc302),a
        ld a,(0xc85a)
        or a
        ld a,3                  ; atlas row y=896, right-facing
        jr z,.row_ready
        ld a,4                  ; atlas row y=1088, left-facing
        ld b,a
        ld a,64
        ld (0xc302),a
        ld a,b
.row_ready:
        ld (0xc303),a
        jp mission_enemy_command
.walk_third:
        ld a,(0xc85a)
        or a
        ld a,128
        jr z,.walk_third_source
        ld a,192
.walk_third_source:
        ld (0xc300),a
        ld a,128
        ld (0xc302),a
        ld a,4
        ld (0xc303),a
        jp mission_enemy_command
.orange_row:
        ld a,(0xc851)
        cp 3
        jr nz,.orange_regular
        ld a,(0xc854)
        cp 8
        jr c,.orange_hands
.orange_regular:
        ld a,(0xc85a)
        or a
        ld a,0
        jr z,.orange_source
        ld a,64
.orange_source:
        ld (0xc302),a
        ld a,10                 ; orange poses at VRAM y=2560/2624
        ld (0xc303),a
        jr mission_enemy_command
.orange_hands:
        ld a,(0xc85a)
        or a
        ld a,0
        jr z,.orange_lower
        ld a,128
.orange_lower:
        ld (0xc300),a
        xor a
        ld (0xc302),a
        ld a,11                 ; captured ground poses at VRAM y=2816
        ld (0xc303),a
        jr mission_enemy_command
.down:
        ld a,(0xc86f)
        cp 2
        jr nz,.blue_down
        ld a,(0xc85a)
        or a
        ld a,64
        jr z,.orange_down_source
        ld a,192
.orange_down_source:
        ld (0xc300),a
        xor a
        ld (0xc302),a
        ld a,11
        ld (0xc303),a
        jr mission_enemy_command
.blue_down:
        ld a,(0xc85a)
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        ld (0xc300),a
        ld a,128                ; atlas row y=1152
        ld (0xc302),a
        ld a,4
        ld (0xc303),a
mission_enemy_command:
        ; Captured poses fit in the central 30 columns and bottom 56 rows.
        ld a,(0xc9a0)
        cp 18
        jr nc,.clip_artwork
        ld b,a
        ld hl,0xc300
        ld a,(hl)
        add a,17
        ld (hl),a
        ld hl,0xc304
        ld a,17
        sub b
        add a,(hl)
        ld (hl),a
        ld a,30
        jr .enemy_width_ready
.clip_artwork:
        ld b,a
        ld hl,0xc300
        ld a,(hl)
        add a,b
        ld (hl),a
        ld a,47
        sub b
.enemy_width_ready:
        ld (0xc308),a
        ld a,(0xc851)
        cp 4
        ld b,8
        ld c,56
        jr nz,.vertical_crop_ready
        ld b,40                 ; down poses occupy the last 24 rows
        ld c,24
.vertical_crop_ready:
        ld hl,0xc302
        ld a,(hl)
        add a,b
        ld (hl),a
        ld hl,0xc306
        ld a,(hl)
        add a,b
        ld (hl),a
        ld a,c
        ld (0xc30a),a
        ld hl,0xc300
        jp command

mission_draw_hud:
        ; The energy bar and the score are shown only in the final fight
        ; (c981): before it the camera moves on most frames, and each move
        ; cleared and copied the whole band again (src/mission_ring.asm).
        ; The score still adds up (c75c), and the ranking shows it.
        ld a,(0xc981)
        or a
        jr nz,.shown
        ld hl,0xc8a6            ; the bar's cache on this page: 0 = band blank
        ld a,(0xc802)
        or a
        jr z,.blank_selected
        inc hl
.blank_selected:
        ld a,(hl)
        or a
        jp z,.score_unchanged
        ld (hl),0
        dec a
        ld (0xc8d2),a           ; the score is drawn when the fight starts
        ld (0xc8d3),a
        ld hl,mission_ring_clear ; the bar's 16 lines black instead (LMMV:
        call copy_command       ; cheaper than the copy, after the strips)
        ld a,16
        ld (0xc306),a
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        call command            ; at the ring position, as the bar's copy
        jp .score_unchanged
.shown:
        ; Top bar isn't touched by the room or actors. Update it only when
        ; damage changes on the current page, keeping both pages coherent.
        ld hl,0xc8a6
        ld a,(0xc802)
        or a
        jr z,.cache_selected
        inc hl
.cache_selected:
        ld a,(0xc856)
        cp (hl)
        jr z,.hud_unchanged
        ld (hl),a
        ld a,255
        ld (0xc9e0),a
        ld (0xc9e1),a
        ld hl,mission_hud_template
        call copy_command
        ld a,(0xc856)
        ld b,a
        ld a,8
        sub b
        add a,a
        add a,a
        add a,a
        add a,a
        ld (0xc302),a
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        call command
.hud_unchanged:
        ; The score is composed off screen (VRAM y 1240, x 128..199) only when
        ; it changes; each page gets it with one copy. The ring renderer
        ; clears the HUD band whenever the camera moves, so this copy is
        ; repeated on most frames: composing there (nine copies and the
        ; digits) took the loop past one frame (make test-mission-walk-timing).
        ld hl,(0xc75c)
        ld de,(MISSION_SCORE_SHOWN)
        or a
        sbc hl,de
        call nz,mission_score_compose
        ld hl,0xc8d2
        ld a,(0xc802)
        or a
        jr z,.score_cache_selected
        inc hl
.score_cache_selected:
        ld a,(MISSION_SCORE_GEN)
        cp (hl)
        jr z,.score_unchanged
        ld (hl),a
        ld hl,mission_score_strip
        call copy_command
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        call command
.score_unchanged:
        ret

; On exhaustion, require the fire button to be released before restarting.
mission_game_over_input:
        xor a
        call in_trig
        or a
        jr nz,.pressed
        ld a,1
        call in_trig
.pressed:
        or a
        jr nz,.restart
        ld a,1
        ld (0xc818),a
        ret
.restart:
        ld a,(0xc818)
        or a
        ret z
        jp init

mission_hud_template:
        dw 0,2304,0,16,256,16
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
; A = digit, D = x; mission_score_cell: A = source x in the score row.
mission_score_digit:
        add a,a
        add a,a
        add a,a
        add a,16
mission_score_cell:
        push de
        push af
        ld hl,mission_score_template
        call copy_command
        pop af
        pop de
        ld (0xc300),a
        ld a,d
        add a,120               ; strip x 128.. for screen x 8..
        ld (0xc304),a
        ld hl,1240
        ld (0xc306),hl          ; into the off-screen strip
        ld hl,0xc300
        jp raw_command          ; command would move it into the ring

; The score (C75C..C75E) composed into the strip at VRAM y 1240,
; x 128..199: red 1P, then the total left-aligned, leading zeros hidden.
; Only the cells that change are drawn (one or two digits for most
; points), so a change costs about as much as a frame's spare time.
; RAM: D0BC..D0BD the low 16 bits composed (points come in hundreds, so
; C75D alone misses 0->100); D0BE counts compositions, never 255, the
; value mission_ring.asm puts in the page caches C8D2/C8D3 to force a copy;
; D0C0 the six cells shown (digit, 10 empty; FE: strip not ready),
; D0C6 the new ones (the ending's RAM, unused while the mission runs).
MISSION_SCORE_SHOWN equ 0xd0bc
MISSION_SCORE_GEN equ 0xd0be
MISSION_SCORE_OLD equ 0xd0c0
MISSION_SCORE_NEW equ 0xd0c6
mission_score_compose:
        ld hl,(0xc75c)
        ld (MISSION_SCORE_SHOWN),hl
        ld hl,MISSION_SCORE_GEN
        inc (hl)
        ld a,(hl)
        inc a
        jr nz,.generation
        ld (hl),a               ; 255 -> 0
.generation:
        ld a,(MISSION_SCORE_OLD)
        cp 0xfe
        jr nz,.ready
        ld hl,mission_score_blank
        call copy_command
        ld hl,0xc300
        call raw_command
        xor a
        ld d,8
        call mission_score_cell
        ld a,8
        ld d,16
        call mission_score_cell
        ld hl,MISSION_SCORE_OLD
        call .empty_cells       ; the strip is clear: all six cells empty
.ready:
        ld hl,MISSION_SCORE_NEW
        call .empty_cells
        ld hl,(0xc75c)
        ld a,(0xc75e)
        ld e,a                  ; E:HL = score
        ld ix,mission_score_powers
        ld iy,MISSION_SCORE_NEW
        ld c,0
.score_digit:
        ld b,0xff
.score_subtract:
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
        jr nc,.score_subtract
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
        jr z,.score_hidden
        ld (iy+0),b
        inc iy
.score_hidden:
        inc ix
        inc ix
        inc ix
        ld a,(ix+0)
        or a
        jr nz,.score_digit
        ld (iy+0),l             ; units, always shown
        ; Draw the cells that differ from the ones shown.
        ld hl,MISSION_SCORE_NEW
        ld de,MISSION_SCORE_OLD
        ld b,6
        ld c,32                 ; screen x of the first digit
.cell:
        ld a,(de)
        cp (hl)
        jr z,.same
        ld a,(hl)
        ld (de),a
        push bc
        push de
        push hl
        ld d,c
        cp 10
        jr z,.clear
        call mission_score_digit
        jr .drawn
.clear:
        call mission_score_erase
.drawn:
        pop hl
        pop de
        pop bc
.same:
        inc hl
        inc de
        ld a,c
        add a,8
        ld c,a
        djnz .cell
        ret
.empty_cells:
        ld b,6
.empty:
        ld (hl),10
        inc hl
        djnz .empty
        ret
; D = screen x: that cell of the strip in black.
mission_score_erase:
        push de
        ld hl,mission_score_one
        call copy_command       ; its LDIs change DE
        pop de
        ld a,d
        add a,120
        ld (0xc304),a
        ld hl,0xc300
        jp raw_command
mission_score_one:
        dw 0,0,0,1240,8,8
        db 0,0x0c,0xff,0xff,0,0,0,0,0x20
mission_score_blank:
        dw 0,0,128,1240,72,8
        db 0,0x0c,0xff,0xff,0,0,0,0,0x20
mission_score_strip:
        dw 128,1240,8,0,72,8
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
mission_score_powers:
        db 0xa0,0x86,0x01, 0x10,0x27,0x00, 0xe8,0x03,0x00
        db 0x64,0x00,0x00, 0x0a,0x00,0x00, 0
mission_score_template:
        dw 0,1232,8,0,8,8
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
; Swap only per-enemy fields; health, cooldown, player and score stay shared.
mission_enemy_swap:
        ; Word exchanges without a loop: c850..c855, c85a..c85b and c858
        ; against the actor record at 0xc870.
        ld hl,(0xc850)
        ld de,(0xc870)
        ld (0xc870),hl
        ld (0xc850),de
        ld hl,(0xc852)
        ld de,(0xc872)
        ld (0xc872),hl
        ld (0xc852),de
        ld hl,(0xc854)
        ld de,(0xc874)
        ld (0xc874),hl
        ld (0xc854),de
        ld hl,(0xc85a)
        ld de,(0xc87a)
        ld (0xc87a),hl
        ld (0xc85a),de
        ld a,(0xc858)
        ld b,a
        ld a,(0xc878)
        ld (0xc858),a
        ld a,b
        ld (0xc878),a
        ret
