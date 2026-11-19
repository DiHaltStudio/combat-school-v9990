; Step 7 combat prototype and post-victory sequence.
; Player: cursor keys, SPACE/button 1 = kick, M/button 2 = jump.
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
        ld hl,palette
        ld bc,0x3061
        otir
        ; Background at VRAM y=512, atlas at y=768.
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        ld a,1
        out (0x63),a
        ld a,1
        ld (0x7000),a
        ld hl,0x8000
        call upload_rle
        xor a
        out (0x64),a
        out (0x63),a
        ld a,0x80
        out (0x63),a
        ld a,1
        out (0x63),a
        ld a,2
        ld (0x7000),a
        ld hl,0x8000
        call upload_rle
        ; The remaining atlas rows follow in VRAM.
        ld a,3
        ld (0x7000),a
        ld hl,0x8000
        call upload_rle
        ; Second atlas (arcade poses, clock digits and texts) at y=1280.
        xor a
        out (0x64),a
        out (0x63),a
        ld a,0x80
        out (0x63),a
        ld a,2
        out (0x63),a
        ld a,ATLAS2_BANK
        ld (0x7000),a
        ld hl,0x8000
        call upload_rle
        ; Third atlas (the arcade moves added on 16-nov: stepping back, kick
        ; in the air, high kick) at y=1600 (atlas3_source).
        xor a
        out (0x64),a
        out (0x63),a
        ld a,0x20
        out (0x63),a
        ld a,3
        out (0x63),a
        ld a,ATLAS3_BANK
        ld (0x7000),a
        ld hl,0x8000
        call upload_rle
        ld hl,0x4000           ; arcade start: player x 64
        ld (0xc800),hl
        xor a
        ld (0xc802),a          ; page
        ld (0xc803),a          ; attack countdown
        ld (0xc804),a          ; jump countdown
        ld (0xc805),a          ; previous trigger 1
        ld (0xc806),a          ; previous trigger 2
        ld (0xc807),a          ; requested direction: 0 stationary, 1 right, 2 left
        ld (0xc808),a          ; horizontal direction captured at takeoff
        ld (0xc809),a          ; facing: 0 right, 1 left
        ld (0xc80a),a          ; current jump height
        ld (0xc80d),a          ; instructor attack countdown
        ld (0xc80e),a          ; instructor cooldown
        ld (0xc80f),a          ; player hit cooldown
        ld (0xc810),a          ; instructor hit cooldown
        ld (0xc811),a          ; instructor faces right
        ld (0xc814),a          ; result: 0 playing, 1 player, 2 instructor
        ld (0xc818),a          ; release latch before restarting
        ld (0xc819),a          ; player walking animation timer
        ld (0xc81a),a          ; instructor walking animation timer
        ld (0xc81e),a          ; queued kick edge
        ld (0xc820),a          ; orange flash (player hit instructor)
        ld (0xc821),a          ; violet flash (instructor hit player)
        ld (0xc822),a          ; instructor recoil countdown
        ld (0xc823),a          ; player recoil countdown
        ld (0xc824),a          ; saved instructor recoil direction
        ld (0xc825),a          ; saved player recoil direction
        ld (0xc826),a          ; instructor retreats after recovering
        ld (0xc827),a          ; close-range counter when cornered
        ld (0xc828),a          ; time since the fight ended
        ld (0xc840),a          ; crouching (down held on the ground)
        ld (0xc841),a          ; current kick: 0 kick, 1 sweep, 2 high, 3 in the air
        ld (0xc850),a          ; the stick's direction (1 up .. 8 up-left)
        ld (0xc851),a          ; stepping back (still facing the instructor)
        ld (0xc842),a          ; instructor attack: 0 kick, 1 punch, 2 sweep
        ld (0xc843),a          ; the time ran out
        ld (0xc845),a          ; clock tenths
        ld a,60                ; arcade clock 1:00.0 (+ Step 6 bonus)
        ld (0xc844),a          ; clock seconds
        ; Jiffies per tenth and READY time (2.1 s), by frame rate.
        ld a,(0x002b)
        bit 7,a
        ld bc,6*256+126
        jr z,.clock_rate
        ld bc,5*256+105
.clock_rate:
        ld a,b
        ld (0xc846),a
        ld a,c
        ld (0xc84c),a
        ld a,1
        ld (0xc849),a          ; READY phase
        ld a,0xff
        ld (0xc84e),a          ; clock not drawn yet
        ld hl,(0xfc9e)
        ld (0xc84a),hl
        ld (0xc847),hl
        ld (0xc82a),a          ; standalone ending stage
        ld (0xc75e),a          ; standalone starts with zero accumulated score
        ld hl,0
        ld (0xc75c),hl
        ld a,(0x002b)
        bit 7,a
        ld a,60
        jr z,.ending_rate_ready
        ld a,50
.ending_rate_ready:
        ld (0xc829),a
        ld a,8
        ld (0xc80b),a          ; player health
        ld (0xc80c),a          ; instructor health
        ld a,160               ; arcade start: instructor x 160
        ld (0xc813),a          ; instructor horizontal position
        ld a,7                  ; instructor fight music (src/psg_calls.asm)
        call psg_play
        ei
loop:
        call update_hit_effects
        ld a,(0xc814)
        or a
        jr nz,.draw
        ld a,(0xc849)
        or a
        jr z,.fight
        ; READY with both fighters still and the clock stopped (arcade).
        ld hl,(0xfc9e)
        ld de,(0xc84a)
        or a
        sbc hl,de
        ld a,(0xc84c)
        ld e,a
        ld d,0
        or a
        sbc hl,de
        jr c,.draw
        xor a
        ld (0xc849),a
        ld hl,(0xfc9e)
        ld (0xc847),hl
.fight:
        call controls
        call instructor_ai
        call update_clock
.draw:
        ld a,(0xc814)
        or a
        jr z,.draw_frame
        cp 1
        jr nz,.advance_result
        ld a,(0xc828)
        cp 160
        jp nc,victory_sequence
.advance_result:
        ld hl,0xc828
        ld a,(hl)
        cp 160
        jr nc,.draw_frame
        inc (hl)
.draw_frame:
        call draw
        ld a,(0xc814)
        cp 2
        call z,result_input
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
        ld a,(0xc802)
        out (0x63),a
        xor 1
        ld (0xc802),a
        ei
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        jp loop
        include "psg_calls.asm"   ; music calls, out of the flow
        include "psg_hats.asm"
; Arcade clock M:SS.t; when it reaches zero the player loses (TIME UP).
update_clock:
        ld a,(0xc814)
        or a
        ret nz
        ld hl,(0xfc9e)
        ld de,(0xc847)
        or a
        sbc hl,de
        ld a,(0xc846)
        ld e,a
        ld d,0
        or a
        sbc hl,de
        ret c
        ld hl,(0xc847)
        add hl,de
        ld (0xc847),hl
        ld a,(0xc845)
        sub 1
        jr nc,.tenth
        ld hl,0xc844
        dec (hl)
        ld a,9
.tenth:
        ld (0xc845),a
        ld hl,0xc844
        or (hl)
        ret nz
        ld a,SFX_TIME_UP        ; the fight warns only at the end (Spectrum)
        call psg_sfx
        ld a,1
        ld (0xc843),a
        ld a,2
        ld (0xc814),a
        xor a
        ld (0xc828),a
        ret
result_input:
        xor a
        call 0x00d8
        or a
        jr nz,.pressed
        ld a,1
        call 0x00d8
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
controls:
        ld a,(0xc823)
        or a
        ret nz                 ; player is recovering from an impact
        ; As the arcade, the player faces the instructor whenever he is on
        ; the ground and not kicking: walking away steps back, a jump keeps
        ; the facing, and landing past the instructor turns him round.
        ld a,(0xc804)
        ld b,a
        ld a,(0xc803)
        or b
        jr nz,.facing_kept
        ld a,(0xc813)
        ld b,a
        ld a,(0xc801)
        cp b
        ld a,0
        jr c,.facing_set
        inc a
.facing_set:
        ld (0xc809),a
.facing_kept:
        ld hl,0xc819
        ld a,(hl)
        or a
        jr z,.read_direction
        dec (hl)
.read_direction:
        xor a
        call 0x00d5
        or a
        jr nz,.direction
        ld a,1
        call 0x00d5
.direction:
        ld b,a
        ld (0xc850),a
        xor a
        ld (0xc807),a
        ; Down, alone or with a side, crouches on the ground (arcade).
        ld c,a
        ld a,b
        sub 4
        cp 3
        jr nc,.not_down
        ld a,(0xc804)
        or a
        jr nz,.not_down
        inc c
        ld b,0                 ; no walking while crouched
.not_down:
        ld a,c
        ld (0xc840),a
        ld a,b
        cp 2
        jr z,.right
        cp 3
        jr z,.right
        cp 4
        jr z,.right
        cp 6
        jr z,.left
        cp 7
        jr z,.left
        cp 8
        jr nz,.air_motion
.left:
        ld a,2
        ld (0xc807),a
        ld a,(0xc804)
        or a
        jr nz,.air_motion
        ld a,(0xc803)
        or a
        jp nz,.buttons
        ld a,(0xc809)          ; facing left: forward (arcade 70h), else
        or a                   ; stepping back (arcade A0h)
        ld de,0xff90
        jr nz,.left_step
        ld de,0xff60
.left_step:
        xor 1
        ld (0xc851),a
        ld hl,(0xc800)
        add hl,de
        ld a,h
        cp 24
        jr c,.buttons
        ld (0xc800),hl
        ld a,8
        ld (0xc819),a
        jr .buttons
.right:
        ld a,1
        ld (0xc807),a
        ld a,(0xc804)
        or a
        jr nz,.air_motion
        ld a,(0xc803)
        or a
        jr nz,.buttons
        ld a,(0xc809)          ; facing right: forward (arcade 70h), else
        or a                   ; stepping back (arcade A0h)
        ld de,0x0070
        jr z,.right_step
        ld de,0x00a0
.right_step:
        ld (0xc851),a
        ld hl,(0xc800)
        add hl,de
        ld a,h
        cp 170
        jr nc,.buttons
        ld (0xc800),hl
        ld a,8
        ld (0xc819),a
        jr .buttons
.air_motion:
        ld a,(0xc804)
        or a
        jr z,.buttons
        ld a,(0xc808)
        or a
        jr z,.buttons
        cp 1
        ld de,0x0200           ; airborne horizontal increments in arcade
        jr z,.air_right
        ld de,0xfe00
        ld a,(0xc809)          ; jumping left facing right: backwards
        or a
        jr nz,.air_step
        ld de,0xfec0           ; arcade: 40 px back against 64 forward
        jr .air_step
.air_right:
        ld a,(0xc809)
        or a
        jr z,.air_step
        ld de,0x0140
.air_step:
        ld hl,(0xc800)
        add hl,de
        ld a,h
        cp 24
        jr c,.buttons
        cp 170
        jr nc,.buttons
        ld (0xc800),hl
.buttons:
        xor a
        call 0x00d8
        or a
        jr nz,.attack_read
        ld a,1
        call 0x00d8
.attack_read:
        ld b,a
        ld a,(0xc805)
        ld c,a
        ld a,b
        ld (0xc805),a
        or a
        jr z,.try_queued_kick
        ld a,c
        or a
        jr nz,.try_queued_kick
        ld a,1
        ld (0xc81e),a
.try_queued_kick:
        ld a,(0xc803)
        or a
        jr nz,.jump_input
        ld a,(0xc81e)
        or a
        jr z,.jump_input
        xor a
        ld (0xc81e),a
        ld a,27                ; 27 frames in the sampled arcade attack
        ld (0xc803),a
        ld a,(0xc840)          ; down + button 1: sweeping kick
        ld (0xc841),a
        ld a,(0xc804)
        or a
        jr z,.ground_kick
        ; In the air: the arcade's jump kick, until landing; too late in the
        ; jump (under 8 frames left) there is none (arcade).
        cp 8
        jr nc,.air_kick
        xor a
        ld (0xc803),a
        jr .jump_input
.air_kick:
        ld (0xc803),a
        ld a,3
        ld (0xc841),a
        jr .jump_input
.ground_kick:
        ld a,(0xc841)
        or a
        jr nz,.jump_input
        ; Up-forward + button 1: the arcade's high kick (31 frames).
        ld a,(0xc850)
        ld b,a
        ld a,(0xc809)
        or a
        ld a,2                 ; up-right facing right
        jr z,.high_direction
        ld a,8                 ; up-left facing left
.high_direction:
        cp b
        jr nz,.jump_input
        ld a,2
        ld (0xc841),a
        ld a,31
        ld (0xc803),a
.jump_input:
        ld a,4
        call 0x0141
        bit 2,a
        ld a,0xff
        jr z,.jump_read
        ld a,2
        call 0x00d8
.jump_read:
        ld b,a
        ld a,(0xc806)
        ld c,a
        ld a,b
        ld (0xc806),a
        or a
        jr z,.tick
        ld a,c
        or a
        jr nz,.tick
        ld a,(0xc803)
        or a
        jr nz,.tick            ; finish the kick before starting a jump
        ld a,(0xc804)
        or a
        jr nz,.tick
        ld a,26
        ld (0xc804),a
        ld a,(0xc807)
        ld (0xc808),a
.tick:
        ld hl,0xc803
        ld a,(hl)
        or a
        jr z,.jump_tick
        dec (hl)
.jump_tick:
        inc hl
        ld a,(hl)
        or a
        ret z
        dec (hl)
        ret

; Initial opponent logic: approach, face the player and kick at close range.
; Timing and hit distances are provisional until the arcade AI is traced.
instructor_ai:
        ld hl,0xc81a
        ld a,(hl)
        or a
        jr z,.hit_cooldowns
        dec (hl)
.hit_cooldowns:
        ld hl,0xc80f
        ld a,(hl)
        or a
        jr z,.cpu_invulnerability
        dec (hl)
.cpu_invulnerability:
        inc hl
        ld a,(hl)
        or a
        jr z,.recoil
        dec (hl)
.recoil:
        ld hl,0xc822
        ld a,(hl)
        or a
        jr z,.player_attack
        dec (hl)
        ld a,(0xc813)
        ld b,a
        ld a,(0xc824)
        or a
        ld a,b
        jr nz,.recoil_left
        cp 170
        ret nc
        inc a
        ld (0xc813),a
        ret
.recoil_left:
        cp 25
        ret c
        dec a
        ld (0xc813),a
        ret
.player_attack:
        ld a,(0xc827)
        or a
        jr z,.check_player_hit
        xor a
        ld (0xc827),a
        ld (0xc826),a
        ld a,43
        ld (0xc80d),a
        ld a,50
        ld (0xc80e),a
        jp .cpu_attack_state
.check_player_hit:
        ld a,(0xc810)
        or a
        jp nz,.cpu_attack
        ld a,(0xc841)
        cp 3
        jr nz,.ground_hit
        ld a,(0xc803)          ; kick in the air: any frame of it
        or a
        jp z,.cpu_attack
        jr .hit_range
.ground_hit:
        cp 2
        ld b,17                ; leg out: ordinary kick and sweep
        jr nz,.hit_frame
        ld b,21                ; high kick: leg out (arcade 152/160)
.hit_frame:
        ld a,(0xc803)
        cp b
        jr nz,.cpu_attack
        ld a,(0xc804)
        or a
        jr nz,.cpu_attack
.hit_range:
        call combat_distance
        call player_kick_range
        jr nc,.cpu_attack
        ld a,SFX_BLOW           ; a blow lands (Spectrum)
        call psg_sfx
        ld hl,0xc80c
        dec (hl)
        push hl
        ld de,500              ; arcade: 500 points per hit landed
        call add_score
        call draw_score
        pop hl
        ld a,25
        ld (0xc810),a          ; keep the existing hit invulnerability
        ld a,10
        ld (0xc80e),a          ; recovery after being hit
        ld a,8
        ld (0xc820),a
        ld a,5                 ; arcade hit response moves five units
        ld (0xc822),a
        ld a,6                 ; retreat before resuming the close-range response
        ld (0xc826),a
        ld a,(0xc811)
        ld (0xc824),a
        or a
        jr nz,.hit_instructor_left
        ld a,(0xc813)
        cp 166
        jr c,.hit_not_cornered
        jr .queue_counter
.hit_instructor_left:
        ld a,(0xc813)
        cp 29
        jr nc,.hit_not_cornered
.queue_counter:
        ld a,1
        ld (0xc827),a
.hit_not_cornered:
        xor a
        ld (0xc80d),a
        ld (0xc81a),a
        ld a,(hl)
        or a
        jr nz,.cpu_attack
        ; Arcade: knocking the instructor down scores 100000 (0x0186A0).
        ld de,0x86a0
        call add_score
        ld hl,0xc75e
        inc (hl)
        call draw_score
        ld a,1
        ld (0xc814),a
        xor a
        ld (0xc828),a
        ret
.cpu_attack:
        ld hl,0xc826
        ld a,(hl)
        or a
        jr z,.cpu_attack_state
        dec (hl)
        ld a,(0xc813)
        ld b,a
        ld a,(0xc824)
        or a
        ld a,b
        jr nz,.retreat_left
        cp 170
        ret nc
        inc a
        jr .retreat_store
.retreat_left:
        cp 25
        ret c
        dec a
.retreat_store:
        ld (0xc813),a
        ld a,8
        ld (0xc81a),a
        ret
.cpu_attack_state:
        ld hl,0xc80d
        ld a,(hl)
        or a
        jr z,.cpu_wait
        dec (hl)
        ; One hit opportunity per attack, at the arcade's moment for each one.
        ld b,a
        ld a,(0xc842)
        ld e,a
        ld d,0
        ld hl,attack_hits
        add hl,de
        ld a,b
        cp (hl)
        ret nz
        ; Crouching dodges the high kick (arcade); the punch and the sweep
        ; are low.
        ld a,e
        or a
        jr nz,.low_attack
        ld a,(0xc840)
        or a
        ret nz
.low_attack:
        ld a,(0xc80f)
        or a
        ret nz
        ld a,(0xc804)
        or a
        ret nz
        call combat_distance
        cp 42
        ret nc
        ld a,SFX_BLOW           ; a blow lands (Spectrum)
        call psg_sfx
        ld hl,0xc80b
        dec (hl)
        ld a,25
        ld (0xc80f),a
        ld a,8
        ld (0xc821),a
        ld a,5
        ld (0xc823),a
        ld a,(0xc811)
        ld (0xc825),a
        ld a,(hl)
        or a
        ret nz
        ld a,2
        ld (0xc814),a
        xor a
        ld (0xc828),a
        ret
.cpu_wait:
        ld hl,0xc80e
        ld a,(hl)
        or a
        jr z,.cpu_seek
        dec (hl)
.cpu_seek:
        call combat_distance
        cp 39                  ; engage earlier, within actual reach
        jr nc,.consider_approach
        ld a,(0xc80e)
        or a
        jr z,.try_attack
.consider_approach:
        ; A kick aimed at the instructor controls its approach, including
        ; a queued kick during the one-frame transition between attacks.
        ld a,(0xc803)
        ld b,a
        ld a,(0xc81e)
        or b
        jr z,.approach_range
        call combat_distance
        call player_threat_range
        ret c
.approach_range:
        call combat_distance
        cp 20                  ; arcade holds around 18–19 internal pixels
        ret c
        ld hl,0xc813
        ld a,(0xc811)
        or a
        jr z,.move_left
        inc (hl)
        ld a,8
        ld (0xc81a),a
        ret
.move_left:
        dec (hl)
        ld a,8
        ld (0xc81a),a
        ret
.try_attack:
        ; Arcade choice: against a crouching player only the high kick; else
        ; about half punches, a third kicks and a few sweeps (MAME).
        ld a,(0xc840)
        or a
        ld a,0
        jr nz,.attack_type
        ld a,r
        and 15
        ld b,1
        cp 8
        jr c,.attack_chosen
        dec b
        cp 14
        jr c,.attack_chosen
        ld b,2
.attack_chosen:
        ld a,b
.attack_type:
        ld (0xc842),a
        ld e,a
        ld d,0
        ld hl,attack_lengths
        add hl,de
        ld a,(hl)
        ld (0xc80d),a
        xor a
        ld (0xc81a),a
        ld a,8                 ; keep pressure between instructor attacks
        ld (0xc80e),a
        ret

; Effects also expire after the fight ends. Knock the player away from the
; instructor using the direction saved on impact, with arena boundaries.
update_hit_effects:
        ld hl,0xc820
        ld a,(hl)
        or a
        jr z,.violet
        dec (hl)
.violet:
        inc hl
        ld a,(hl)
        or a
        jr z,.player_recoil
        dec (hl)
.player_recoil:
        ld hl,0xc823
        ld a,(hl)
        or a
        ret z
        dec (hl)
        ld a,(0xc825)
        or a
        ld de,0xff00           ; instructor faces left, player moves left
        jr z,.player_step
        ld de,0x0100
.player_step:
        ld hl,(0xc800)
        add hl,de
        ld a,h
        cp 24
        ret c
        cp 170
        ret nc
        ld (0xc800),hl
        ret

; Returns distance in A and updates instructor facing (0 left, 1 right).
combat_distance:
        ld a,(0xc813)
        ld b,a
        ld a,(0xc801)
        cp b
        jr nc,.cpu_faces_right
        ld a,b
        ld b,a
        ld a,(0xc801)
        ld c,a
        ld a,b
        sub c
        ld b,a
        xor a
        ld (0xc811),a
        ld a,b
        ret
.cpu_faces_right:
        sub b
        ld b,a
        ld a,1
        ld (0xc811),a
        ld a,b
        ret

; A=distance, c811=instructor facing. Carry means the player faces the
; instructor and the visible extended leg reaches its torso. Sprite origins
; differ after mirroring, so the left and right limits are intentionally not
; equal. Keep the AI's threat check and actual hit check on this same test.
player_kick_range:
        ld c,a
        ld a,(0xc811)
        ld b,a
        ld a,(0xc809)
        cp b
        jr z,.facing
        or a                   ; clear carry for a kick facing away
        ret
.facing:
        or a
        ld a,c
        jr z,.right
        cp 24
        ret
.right:
        cp 41
        ret

; Keep a small buffer beyond the visible kick before approaching. This
; prevents the instructor stepping back into a stationary repeating kick.
player_threat_range:
        ld c,a
        ld a,(0xc811)
        ld b,a
        ld a,(0xc809)
        cp b
        jr z,.facing
        or a
        ret
.facing:
        or a
        ld a,c
        jr z,.right
        cp 31
        ret
.right:
        cp 48
        ret
draw:
        ld hl,field_template
        call copy_command
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld hl,actor_template
        call copy_command
        ld a,(0xc809)
        or a
        jr z,.facing_ready
        ld a,64                ; mirrored poses at VRAM y=832
        ld (0xc302),a
.facing_ready:
        ld a,(0xc814)
        cp 1
        jr nz,.pose_fight
        ; Player won: standing, then both arms raised after 2.5 s (arcade; the
        ; loop runs about 30 times per second here).
        xor a
        ld (0xc80a),a
        ld a,(0xc828)
        cp 75
        jr nc,.arms_up
        cp 70
        ld a,0
        jr c,.pose_won
        ld a,192               ; turning to the front at VRAM y=1536
        ld (0xc300),a
        xor a
        ld (0xc302),a
        ld a,6
        ld (0xc303),a
        jp .ground_y
.arms_up:
        ld a,0x80              ; arms raised at VRAM y=896
        ld (0xc302),a
        xor a
.pose_won:
        ld (0xc300),a
        jp .ground_y
.pose_fight:
        ld a,(0xc841)
        cp 2
        jr nz,.not_high_kick
        ld a,(0xc803)
        or a
        jr z,.not_high_kick
        ; High kick: 31 frames, a pose every 4 (arcade 139, 142, 152, 160,
        ; 164, 232, then recovery 128 and standing).
        ld b,a
        ld a,31
        sub b
        rrca
        rrca
        and 7
        cp 6
        jr nc,.high_recovery
        add a,3
        call atlas3_source
        jr .high_ground
.high_recovery:
        jr nz,.high_standing
        ld a,128               ; arcade recovery (128/132) at VRAM y=1408
        ld b,0x80
        ld c,5
        call extra_source
        jr .high_ground
.high_standing:
        xor a
        ld (0xc300),a
.high_ground:
        xor a
        ld (0xc80a),a
        jp .ground_y
.not_high_kick:
        ld a,(0xc803)
        or a
        ld a,0
        jr z,.pose_jump
        ld a,64
        ld b,a
        ld a,(0xc803)
        cp 22
        jr nc,.kick_prepare
        cp 5
        ld a,b
        jr nc,.pose_jump
.kick_prepare:
        xor a                  ; arcade wind-up (144/148) at VRAM y=1408
        ld b,0x80
        ld c,5
        call extra_source
        jr .pose_air
.pose_jump:
        ld (0xc300),a
.pose_air:
        ld a,(0xc804)
        or a
        jr z,.ground
        ld a,(0xc803)
        or a
        jr z,.jump_poses
        ld a,(0xc841)
        cp 3
        jr nz,.jump_poses
        ld a,2                 ; arcade 116: the kick in the air
        call atlas3_source
        jr .jump_height
.jump_poses:
        ld a,(0xc804)
        ; Arcade jump: leg out, tucked in the middle (frames 6..13), leg out.
        cp 13
        jr c,.leg_out
        cp 21
        jr nc,.leg_out
        ld a,128
        ld (0xc300),a
        ld a,3
        ld (0xc303),a
        ld a,(0xc809)
        or a
        ld a,0
        jr z,.tuck_row
        ld a,64
.tuck_row:
        ld (0xc302),a
        jr .jump_height
.leg_out:
        xor a                  ; leg out at VRAM y=1472
        ld b,0xc0
        ld c,5
        call extra_source
.jump_height:
        ld a,(0xc804)
        ld e,a
        ld d,0
        ld hl,jump_heights
        add hl,de
        ld a,(hl)
        ld (0xc80a),a
        ld b,a
        ld a,90
        sub b
        jp .player_y
.ground:
        xor a
        ld (0xc80a),a
        ; Crouch and sweeping kick at VRAM y=1216, mirrored at x+128.
        ld a,(0xc803)
        or a
        jr z,.crouch_check
        ld a,(0xc841)
        or a
        jr z,.kick_ground
        ld a,(0xc803)
        cp 22
        jr nc,.crouch_pose
        cp 5
        jr c,.recovery_pose
        ld a,64
        jr .low_row
.recovery_pose:
        ld a,128               ; arcade recovery (128/132) at VRAM y=1408
        ld b,0x80
        ld c,5
        call extra_source
        jr .ground_y
.crouch_check:
        ld a,(0xc840)
        or a
        jr z,.kick_ground
.crouch_pose:
        xor a
.low_row:
        ld b,a
        ld a,(0xc809)
        or a
        ld a,b
        jr z,.low_x
        add a,128
.low_x:
        ld (0xc300),a
        ld a,0xc0
        ld (0xc302),a
        ld a,4
        ld (0xc303),a
        jr .ground_y
.kick_ground:
        ld a,(0xc803)
        or a
        jr nz,.ground_y
        ld a,(0xc819)
        or a
        jr z,.ground_y
        ld a,(0xc851)
        or a
        jr z,.walk_forward
        ld a,(0xfc9e)          ; stepping back: arcade 88 and 96
        and 8
        ld a,0
        jr z,.back_pose
        inc a
.back_pose:
        call atlas3_source
        jr .ground_y
.walk_forward:
        ld a,(0xfc9e)
        and 8
        jr z,.walk_player_first
        ld a,64
.walk_player_first:
        ld (0xc300),a
        ld a,(0xc809)
        or a
        ld a,0xc0              ; normal walk sprites at y=960
        jr z,.walk_player_source
        xor a                  ; mirrored walk sprites at y=1024
        ld (0xc302),a
        ld a,4
        ld (0xc303),a
        jr .ground_y
.walk_player_source:
        ld (0xc302),a
.ground_y:
        ld a,90
.player_y:
        ld (0xc306),a
        ld a,(0xc801)
        ld (0xc304),a
        ld a,(0xc814)
        cp 2
        jr nz,.player_result_ready
        ld a,(0xc843)
        or a
        jr z,.knocked_down
        ; Time up: the player stands, then kneels (arcade).
        ld a,90
        ld (0xc306),a
        ld a,(0xc828)
        cp 70
        jr nc,.kneel
        xor a
        ld (0xc300),a
        ld a,3
        ld (0xc303),a
        ld a,(0xc809)
        or a
        ld a,0
        jr z,.stand_row
        ld a,64
.stand_row:
        ld (0xc302),a
        jr .player_result_ready
.kneel:
        ld a,128               ; kneeling at VRAM y=1472
        ld b,0xc0
        ld c,5
        call extra_source
        jr .player_result_ready
.knocked_down:
        ld a,4
        ld (0xc303),a
        ld a,(0xc809)
        or a
        ld a,64                ; fall poses y=1088; mirrored y=1152
        jr z,.player_fall_row
        ld a,128
.player_fall_row:
        ld (0xc302),a
        ld a,128               ; hit reaction
        ld (0xc300),a
        ld a,(0xc828)
        cp 12
        jr c,.player_result_ready
        ld a,192               ; lying on the floor
        ld (0xc300),a
        ld a,138
        ld (0xc306),a
.player_result_ready:
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld hl,actor_template
        call copy_command
        ld a,192
        ld (0xc300),a
        ld a,(0xc811)
        or a
        jr z,.cpu_left
        ld a,128               ; mirrored instructor at VRAM y=896
        ld (0xc302),a
        ld a,(0xc80d)
        or a
        jr z,.cpu_position
        ld a,128
        ld (0xc300),a
        jr .cpu_position
.cpu_left:
        ld a,(0xc80d)
        or a
        jr z,.cpu_position
        ld a,64                ; left-facing kick at VRAM y=832
        ld (0xc302),a
.cpu_position:
        ld a,(0xc80d)
        or a
        call nz,cpu_attack_pose
        ld a,(0xc80d)
        or a
        jr nz,.cpu_x
        ld a,(0xc81a)
        or a
        jr z,.cpu_x
        ld a,(0xfc9e)
        and 8
        ld a,128
        jr z,.cpu_walk_frame
        ld a,192
.cpu_walk_frame:
        ld (0xc300),a
        ld a,(0xc811)
        or a
        ld a,0xc0              ; normal instructor walk y=960
        jr z,.cpu_walk_source
        xor a                  ; reflected instructor walk y=1024
        ld (0xc302),a
        ld a,4
        ld (0xc303),a
        jr .cpu_x
.cpu_walk_source:
        ld (0xc302),a
.cpu_x:
        ld a,(0xc813)
        ld b,a
        ld a,(0xc80d)
        or a
        jr z,.cpu_x_ready
        ld a,(0xc811)
        or a
        jr nz,.cpu_x_ready
        ld a,b
        ld hl,0xc83b           ; extended leg or arm reaches left
        sub (hl)
        ld b,a
.cpu_x_ready:
        ld a,b
        ld (0xc304),a
        ld a,90
        ld (0xc306),a
        ld a,(0xc814)
        cp 1
        jr nz,.cpu_result_ready
        ld a,4
        ld (0xc303),a
        ld a,(0xc811)
        or a
        ld a,64
        jr z,.cpu_fall_row
        ld a,128
.cpu_fall_row:
        ld (0xc302),a
        xor a                  ; hit reaction
        ld (0xc300),a
        ld a,(0xc828)
        cp 12
        jr c,.cpu_result_ready
        ld a,64                ; lying on the floor
        ld (0xc300),a
        ld a,138
        ld (0xc306),a
.cpu_result_ready:
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        call command
        call draw_hit_flashes
        call draw_damage
        call draw_clock
        ld a,(0xc849)
        or a
        jr z,.no_ready
        ; READY and the fighters' names, as the arcade.
        ld hl,label_ready
        call label_blit
        ld hl,label_names
        call label_blit
        ld hl,label_titles
        jp label_blit
.no_ready:
        ld a,(0xc814)
        or a
        ret z
        cp 1
        jr z,.won_labels
        ld a,(0xc843)
        or a
        jr z,.lost_labels
        ld hl,label_time_up
        call label_blit
.lost_labels:
        ; Arcade: PLAYER 1 / (NICK) / YOU BLEW IT.
        ld a,(0xc828)
        cp 75
        ret c
        ld hl,label_player
        call label_blit
        ld hl,label_nick
        call label_blit
        ld hl,label_blew_it
        jr label_blit
.won_labels:
        ; Arcade: PLAYER 1 / (NICK) / YOU MADE IT with the arms raised.
        ld a,(0xc828)
        cp 75
        ret c
        ld hl,label_player
        call label_blit
        ld hl,label_nick
        call label_blit
        ld hl,label_made_it
; HL = sx, sy (word), dx, dy, width, height; second atlas (VRAM y 1280..).
label_blit:
        push hl
        ld hl,result_template
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
        ld a,(0xc802)
        ld (de),a
        inc de
        ldi
        inc de
        ldi
        ld hl,0xc300
        jp command
label_ready:    db 0
                dw 1568
                db 104,64,40,8
label_names:    db 0
                dw 1552
                db 48,80,112,8
label_titles:   db 0
                dw 1560
                db 58,88,181,8
label_time_up:  db 64
                dw 1568
                db 103,64,55,8
label_player:   db 0
                dw 1552
                db 48,80,64,8
label_nick:     db 0
                dw 1560
                db 58,88,48,8
label_made_it:  db 0
                dw 1576
                db 81,104,87,8
label_blew_it:  db 96
                dw 1576
                db 81,104,87,8
; Clock M:SS.t at the arcade position (104,26); glyphs at VRAM y=1536.
; Drawn opaque into the background source (VRAM y=512+26), only when it
; changes: redrawing it on both pages every frame slowed the fight down.
draw_clock:
        ld a,(0xc84e)
        inc a
        jr nz,.drawn_before
        ld a,10                ; ':' and '.' once
        ld d,112
        call clock_digit
        ld a,11
        ld d,136
        call clock_digit
        ld a,0xfe
        ld (0xc84f),a          ; force the seconds
        call draw_score
.drawn_before:
        ld a,(0xc845)
        ld hl,0xc84e
        cp (hl)
        jr z,.seconds
        ld (hl),a
        ld d,144
        call clock_digit
.seconds:
        ld a,(0xc844)
        ld hl,0xc84f
        cp (hl)
        ret z
        ld (hl),a
        ld b,0
        cp 60
        jr c,.minutes
        sub 60
        inc b
.minutes:
        ld c,a
        ld a,b
        ld d,104
        call clock_digit
        ld a,c
        ld b,0
.tens:
        cp 10
        jr c,.ones
        sub 10
        inc b
        jr .tens
.ones:
        ld c,a
        ld a,b
        ld d,120
        call clock_digit
        ld a,c
        ld d,128
        jp clock_digit
; A = glyph (0-9, 10 ':', 11 '.'), D = destination x.
clock_digit:
        push bc
        push de
        add a,a
        add a,a
        add a,a
        add a,64
        push af
        ld hl,clock_template
        call copy_command
        pop af
        ld (0xc300),a
        pop de
        ld a,d
        ld (0xc304),a
        ld a,2                 ; background source at VRAM y=512
        ld (0xc307),a
        ld hl,0xc300
        call command
        pop bc
        ret
; DE = points added to the game score C75C..C75E (24 bits, little endian).
add_score:
        ld hl,(0xc75c)
        add hl,de
        ld (0xc75c),hl
        ret nc
        ld hl,0xc75e
        inc (hl)
        ret

; Single game score in the black band at the top left, above the lamps:
; red 1 and P from the background's PLAYER 1 at x 4 and 12, the total from x 28
; in clock digits. Like the clock it is drawn opaque into the background
; source (VRAM y=512), only when the score changes.
draw_score:
        ld hl,score_label_1
        call background_label
        ld hl,score_label_p
        call background_label
        ld hl,(0xc75c)
        ld a,(0xc75e)
        ld e,a                  ; E:HL = score
        ld ix,score_powers
        ld d,28
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
        call score_digit
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
; A = digit, D = x: clock glyph at y 1 of the background source.
score_digit:
        add a,a
        add a,a
        add a,a
        add a,64
        push af
        push de
        ld hl,clock_template
        call copy_command
        pop de
        pop af
        ld (0xc300),a
        ld a,d
        ld (0xc304),a
        ld a,1
        ld (0xc306),a
        ld a,2                 ; background source at VRAM y=512
        ld (0xc307),a
        ld hl,0xc300
        jp command
; HL = label as label_blit, drawn into the background source.
background_label:
        push hl
        ld hl,result_template
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
        ld a,2
        ld (de),a
        inc de
        ldi
        inc de
        ldi
        ld hl,0xc300
        jp command
score_label_1:  db 96                 ; red 1 and P of the background's
                dw 550                 ; PLAYER 1 (rows 38-43, VRAM y 550)
                db 4,5,8,6
score_label_p:  db 40
                dw 550
                db 12,5,8,6
score_powers:
        db 0xa0,0x86,0x01, 0x10,0x27,0x00, 0xe8,0x03,0x00
        db 0x64,0x00,0x00, 0x0a,0x00,0x00, 0

; Third-atlas source (tools/build_step7_visual.py ATLAS3): A = pose 0..8 at
; x (A&3)*64, y 1600+(A>>2)*64; facing left, 192 lines lower.
atlas3_source:
        ld b,a
        and 3
        rrca
        rrca
        ld (0xc300),a
        ld a,b
        and 0x0c               ; (A>>2)*64 = (A&0Ch)*16
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,1600
        add hl,de
        ld a,(0xc809)
        or a
        jr z,.row
        ld de,192
        add hl,de
.row:
        ld a,l
        ld (0xc302),a
        ld a,h
        ld (0xc303),a
        ret
; Second-atlas source: A = x facing right (x+64 facing left), B and C =
; low and high bytes of the VRAM row.
extra_source:
        ld e,a
        ld a,(0xc809)
        or a
        ld a,e
        jr z,.right
        add a,64
.right:
        ld (0xc300),a
        ld a,b
        ld (0xc302),a
        ld a,c
        ld (0xc303),a
        ret
; Instructor attack in progress: pose from the frames elapsed (MAME) and
; c83b, how far the pose reaches left of the instructor when facing left.
cpu_attack_pose:
        ld a,(0xc842)
        ld e,a
        ld d,0
        ld hl,attack_lengths
        add hl,de
        ld a,(hl)
        ld hl,0xc80d
        sub (hl)
        ld b,a
        ld a,16
        ld (0xc83b),a
        ld a,e
        or a
        jr nz,.not_kick
        ld a,b
        cp 13
        jr c,.idle
        cp 31
        ret c                  ; the kick source is already selected
        jr .idle
.not_kick:
        dec a
        ld a,b
        jr nz,.sweep
        cp 6
        jr c,.idle
        cp 12
        jr c,.crouch
        cp 32
        jr nc,.idle
        xor a                  ; punch at VRAM y=1280
        ld c,0
        jr .extra
.crouch:
        xor a                  ; crouching before the punch, y=1344
        ld c,0x40
        jr .extra_still
.sweep:
        cp 10
        jr c,.idle
        cp 14
        jr c,.sweep_prep
        cp 32
        jr c,.sweep_out
        cp 34
        jr nc,.idle
.sweep_prep:
        ld a,128               ; before and after the sweep, y=1344
        ld c,0x40
        jr .extra_still
.sweep_out:
        ld a,128               ; sweep at VRAM y=1280
        ld c,0
        jr .extra
.extra_still:
        ld b,a
        xor a
        ld (0xc83b),a
        ld a,b
.extra:
        ld b,a
        ld a,(0xc811)
        or a
        ld a,b
        jr z,.facing_left
        add a,64
.facing_left:
        ld (0xc300),a
        ld a,c
        ld (0xc302),a
        ld a,5
        ld (0xc303),a
        ret
.idle:
        xor a
        ld (0xc83b),a
        ld a,192
        ld (0xc300),a
        ld a,(0xc811)
        or a
        ld a,0
        jr z,.idle_row
        ld a,128
.idle_row:
        ld (0xc302),a
        ret
clock_template:
        dw 64,1536,0,26,8,13
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40

draw_hit_flashes:
        ld a,(0xc820)
        or a
        jr z,.player_flash
        ld hl,flash_template
        call copy_command
        ld a,(0xc813)
        ld b,a
        ld a,(0xc811)
        or a
        ld a,b
        jr z,.instructor_x_ready
        add a,16
.instructor_x_ready:
        ld (0xc304),a
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        call command
.player_flash:
        ld a,(0xc821)
        or a
        ret z
        ld hl,flash_template
        call copy_command
        ld a,112
        ld (0xc300),a
        ld a,(0xc801)
        add a,8
        ld (0xc304),a
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        jp command

; Colour one small block per hit over the original empty damage bars.
draw_damage:
        ld a,(0xc80b)
        ld b,a
        ld a,8
        sub b
        ld (0xc815),a
        xor a
        ld (0xc81b),a
        ld a,97                ; player cells grow away from DAMAGE
        call draw_damage_bar
        ld a,(0xc80c)
        ld b,a
        ld a,8
        sub b
        ld (0xc815),a
        ld a,1
        ld (0xc81b),a
        ld a,151
draw_damage_bar:
        ld (0xc816),a
.cell:
        ld a,(0xc815)
        or a
        ret z
        ld hl,damage_template
        call copy_command
        ld a,(0xc81b)
        or a
        ld a,0x33              ; instructor damage is violet
        jr nz,.colour_ready
        ld a,0x99              ; player damage is orange
.colour_ready:
        ld (0xc310),a
        ld (0xc311),a
        ld a,(0xc816)
        ld (0xc304),a
        cp 151
        jr nz,.cell_width_ready
        ld a,8                 ; first instructor cell has an extra pixel
        ld (0xc308),a
.cell_width_ready:
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld hl,0xc815
        dec (hl)
        ld a,(0xc816)
        ld b,a
        ld a,(0xc81b)
        or a
        ld a,b
        jr nz,.next_right
        sub 8
        jr .next_cell
.next_right:
        cp 151
        jr nz,.regular_right
        inc a
.regular_right:
        add a,8
.next_cell:
        ld (0xc816),a
        jr .cell
; Winning standalone sequence: map, sampled ceremony, flag and rank.
; RLE frames are packed into switchable banks and share the same decoder.
victory_sequence:
        call psg_stop           ; the map is silent
        xor a
        ld (0xc82a),a
        ld (0xc836),a          ; previous image is not a flag frame
        ld (0xc837),a          ; ending display page
        call ending_show
        ld a,1
        ld (0xc82a),a
        ; Blink the five completed steps visible on this scrolled map.
        ld a,6
        ld (0xc82b),a
.map_blink:
        ld a,(0xc82b)
        and 1
        call ending_map_cells
        call ending_half_second
        ld hl,0xc82b
        dec (hl)
        jr nz,.map_blink
        ld a,1
        call ending_show
        ld a,(0xf207)
        cp 1
        jr nz,.normal_music
        ld a,ARC_WICKED_CHILD
        call psg_arcade         ; MSX flag: PSG from the formation onwards
        jr .formation
.normal_music:
        call psg_hats           ; hats in the air, then the graduation (song 0)
.formation:
        ld a,2
        ld (0xc82a),a
        ; Load the ceremony while the formation is on screen (about 1 s).
        call ceremony_load
        ld a,4
        call ending_seconds
        ld a,3
        ld (0xc82a),a
        call ceremony
        ld a,7
        call ending_show
        ld a,4
        ld (0xc82a),a
        call ending_rank_arrow
        xor a
        ld (0xc818),a
.rank_wait:
        halt
        call result_input
        jr .rank_wait

; A=frame index. Each bank contains palette and count/value RLE pairs.
ending_screen:
        di
.wait_command:
        in a,(0x65)
        rrca
        jr c,.wait_command
.new_scene:
        xor a
        ld (0xc836),a
        ld (0xc837),a
        ld (0xc838),a
        call display_off        ; off from the next frame on
.load_data:
        ; The caller's frame index is stored before disabling the display.
        ld a,(0xc82c)
        ld e,a
        ld d,0
        ld hl,ending_frames
        add hl,de
        add hl,de
        add hl,de
        ld a,(hl)
        ld (0x7000),a
        ld (0xc839),a          ; bank of the current compressed stream
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
        xor a
        out (0x64),a
        out (0x63),a
        ld a,(0xc837)
        rrca
        out (0x63),a
        xor a
        out (0x63),a
        call ending_upload_rle
        ; Switch only at vertical blank so moving flag frames do not tear.
.vblank_end:
        in a,(0x65)
        bit 6,a
        jr nz,.vblank_end
.vblank_start:
        in a,(0x65)
        bit 6,a
        jr z,.vblank_start
        ld a,18
        out (0x64),a
        ld a,(0xc837)
        out (0x63),a
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ei
        ret


; HL = count/value RLE pairs (ended by a zero count) in the bank of C839,
; written to the current VRAM address; crosses to the next bank at 0xC000.
ending_upload_rle:
.next_run:
        ; Streams are word-aligned and cross banks only between RLE pairs.
        ld a,h
        cp 0xc0
        jr nz,.read_run
        ld a,(0xc839)
        inc a
        ld (0xc839),a
        ld (0x7000),a
        ld hl,0x8000
.read_run:
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
        jr .next_run

        include "step7_ceremony.asm"

; Entry wrapper stores A because VDP setup reuses it.
ending_show:
        ld (0xc82c),a
        jp ending_screen

ending_half_second:
        ld a,(0xc829)
        srl a
        jp ending_frames_wait
ending_seconds:
        ld b,a
        ld a,(0xc829)
        ld e,a
        ld d,0
        ld hl,0
.multiply:
        add hl,de
        djnz .multiply
        ld (0xc82d),hl
        jr ending_wait_start
ending_frames_wait:
        ld l,a
        ld h,0
        ld (0xc82d),hl
ending_wait_start:
        ld hl,(0xfc9e)
        ld (0xc82f),hl
.wait:
        halt
        ld hl,(0xfc9e)
        ld de,(0xc82f)
        or a
        sbc hl,de
        ld de,(0xc82d)
        or a
        sbc hl,de
        jr c,.wait
        ret

; A=0/1: completed map squares alternate gold and white.
ending_map_cells:
        or a
        ld a,ENDING_MAP_GOLD
        jr z,.colour
        ld a,ENDING_MAP_WHITE
.colour:
        ld b,a
        rlca
        rlca
        rlca
        rlca
        or b
        ld (0xc831),a
        ld a,62
        ld (0xc832),a
        ld a,5
        ld (0xc833),a
.cell:
        ld hl,ending_map_cell
        call copy_command
        ld a,(0xc832)
        ld (0xc306),a
        ld a,(0xc831)
        ld (0xc310),a
        ld (0xc311),a
        ld hl,0xc300
        call command
        ld a,(0xc832)
        add a,30
        ld (0xc832),a
        ld hl,0xc833
        dec (hl)
        jr nz,.cell
        ret

; Score in c75c..c75e is a 24-bit little-endian total. The video shows
; the first five ranks; mission-dependent officer ranks are not guessed.
ending_rank_arrow:
        ld a,(0xc75e)
        cp 3
        jr c,.rookie
        jr nz,.master
        ld hl,(0xc75c)
        ld de,0x0d41           ; strictly over 200000
        or a
        sbc hl,de
        jr c,.rookie
        ld hl,(0xc75c)
        ld de,0x5b61           ; strictly over 220000
        or a
        sbc hl,de
        ld a,1
        jr c,.row
        ld hl,(0xc75c)
        ld de,0xa981           ; strictly over 240000
        or a
        sbc hl,de
        ld a,2
        jr c,.row
        ld hl,(0xc75c)
        ld de,0xf7a1           ; strictly over 260000
        or a
        sbc hl,de
        ld a,3
        jr c,.row
.master:
        ld a,4
        jr .row
.rookie:
        xor a
.row:
        ld (0xc834),a
        ld e,a
        ld d,0
        ld hl,ending_rank_rows
        add hl,de
        ld l,(hl)
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl              ; y * 128
        ld de,4                ; x=8, the arcade's cell 1
        add hl,de
        ld ix,ending_arrow
        ld c,8
.arrow_row:
        xor a
        out (0x64),a
        ld a,l
        out (0x63),a
        ld a,h
        out (0x63),a
        xor a
        out (0x63),a
        ld b,12                 ; "1P>" in the arcade font, 24 pixels
.arrow_byte:
        ld a,(ix+0)
        out (0x60),a
        inc ix
        djnz .arrow_byte
        ld de,128
        add hl,de
        dec c
        jr nz,.arrow_row
        ret
        include "../build/step7/rank-rows.inc"

; The squares of steps 7..3: 16x29 from line 62, one every 30 lines (the
; map's bands lose 2 lines each to fit in 212, tools/extract_progress_maps.py).
ending_map_cell:
        dw 0,0,16,62,16,29
        db 0,0x0c,0xff,0xff,0x33,0x33,0,0,0x20
ending_arrow: incbin "../build/step7/rank-arrow.bin"
        include "../build/step7/ending.inc"
ATLAS3_BANK equ ATLAS2_BANK+1  ; atlas3-rle-bank.bin follows atlas2 (integrated: bank 56)

copy_command:
        ld de,0xc300
        ld bc,21
        ldir
        ret
upload_rle:
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
        jr upload_rle
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
field_template:
        dw 0,512,0,0,256,212
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
actor_template:
        dw 0,768,0,100,64,64
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
damage_template:
        dw 0,0,97,45,7,8
        db 0,0x0c,0xff,0xff,0x99,0x99,0,0,0x20
result_template:
        dw 0,896,86,62,96,16
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
flash_template:
        dw 96,896,0,108,16,16
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
; Instructor attacks (kick, punch, sweep): duration and hit moment, in
; frames from MAME (the hit is counted when c80d still holds this value).
attack_lengths: db 43,37,43
attack_hits:    db 24,20,27
jump_heights:
        ; Indexed by the countdown (26 at take-off): a parabola up to 42 px
        ; (arcade peak), 26 frames instead of the arcade's 36 (faster, asked
        ; by the user on 11 November).
        db 3,6,12,17,22,26,30,33,36,38,40,41,42,42
        db 42,41,40,38,36,33,30,26,22,17,12,6,0
regs:   db 0x81,0,0x42,0
settings: db 0,0,0,0,0,0,0,0
palette: incbin "../build/step7/palette.bin"
        assert $ <= 0x8000
        ds 0x8000-$,0xff
        incbin "../build/step7/field-rle-bank.bin"
        incbin "../build/step7/atlas0-rle-bank.bin"
        incbin "../build/step7/atlas1-rle-bank.bin"
        incbin "../build/step7/ending.bin"
        incbin "../build/step7/atlas2-rle-bank.bin"
        incbin "../build/step7/atlas3-rle-bank.bin"
