; Frozen mission input/render scaffold derived from Step 7.
; build_mission_visual.py selects only setup, player input/draw and V9990 helpers.
; The instructor and ending below are not included in the mission ROM.
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
        ; Mission atlas at y=768; the obsolete initial bitmap is omitted.
        xor a
        out (0x64),a
        out (0x63),a
        ld a,0x80
        out (0x63),a
        ld a,1
        out (0x63),a
        ld a,1
        ld (0x7000),a
        ld hl,0x8000
        call upload_rle
        ; The remaining atlas rows follow in VRAM.
        ld a,2
        ld (0x7000),a
        ld hl,0x8000
        call upload_rle
        ld hl,0x4600
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
        ld a,110
        ld (0xc813),a          ; instructor horizontal position
        ei
loop:
        call update_hit_effects
        ld a,(0xc814)
        or a
        jr nz,.draw
        call controls
        call instructor_ai
.draw:
        ld a,(0xc814)
        or a
        jr z,.draw_frame
        cp 1
        jr nz,.advance_result
        ld a,(0xc828)
        cp 180
        jp nc,victory_sequence
.advance_result:
        ld hl,0xc828
        ld a,(hl)
        cp 180
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
        jr loop
result_input:
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
controls:
        ld a,(0xc823)
        or a
        ret nz                 ; player is recovering from an impact
        ld hl,0xc819
        ld a,(hl)
        or a
        jr z,.read_direction
        dec (hl)
.read_direction:
        xor a
        call in_stick
        or a
        jr nz,.direction
        ld a,1
        call in_stick
.direction:
        ld b,a
        xor a
        ld (0xc807),a
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
        ld a,1
        ld (0xc809),a
        ld a,2
        ld (0xc807),a
        ld a,(0xc804)
        or a
        jr nz,.air_motion
        ld a,(0xc803)
        or a
        jr nz,.buttons
        ld hl,(0xc800)
        ld de,0xff60           ; observed arcade left increment
        add hl,de
        ld a,h
        cp 24
        jr c,.buttons
        ld (0xc800),hl
        ld a,8
        ld (0xc819),a
        jr .buttons
.right:
        xor a
        ld (0xc809),a
        ld a,1
        ld (0xc807),a
        ld a,(0xc804)
        or a
        jr nz,.air_motion
        ld a,(0xc803)
        or a
        jr nz,.buttons
        ld hl,(0xc800)
        ld de,0x0070           ; observed arcade right increment
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
        jr z,.air_step
        ld de,0xfe00
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
        call in_trig
        or a
        jr nz,.attack_read
        ld a,1
        call in_trig
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
.jump_input:
        ld a,4
        call in_snsmat
        bit 2,a
        ld a,0xff
        jr z,.jump_read
        ld a,2
        call in_trig
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
        ld a,32
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

; Direct input for the mission (interrupts are off): what the BIOS GTSTCK,
; GTTRIG and SNSMAT return, read from the PPI and the PSG ports. The BIOS
; calls cost about 1.3 ms a frame. Keep BC, DE, HL.
; A = keyboard row: A = its bits (0 = pressed).
in_snsmat:
        push bc
        ld b,a
        in a,(0xaa)
        and 0xf0
        or b
        out (0xaa),a
        in a,(0xa9)
        pop bc
        ret
; A = 0 (cursor keys) or 1 (joystick 1): A = direction 0..8.
in_stick:
        push de
        or a
        jr nz,.joystick
        ld a,8
        call in_snsmat
        rrca
        rrca
        rrca
        rrca                    ; left, up, down, right in bits 0..3
        ld de,in_stick_keys
        jr .lookup
.joystick:
        call in_joystick        ; up, down, left, right in bits 0..3
        ld de,in_stick_joy
.lookup:
        cpl
        and 15
        add a,e
        ld e,a
        adc a,d
        sub e
        ld d,a
        ld a,(de)
        pop de
        ret
; A = 0 (space), 1 or 2 (joystick 1 buttons A, B): A = 255 pressed, else 0.
in_trig:
        or a
        jr nz,.joystick
        ld a,8
        call in_snsmat
        cpl
        and 1
        jr .result
.joystick:
        dec a
        push bc
        ld b,0x10
        jr z,.button
        ld b,0x20
.button:
        call in_joystick
        cpl
        and b
        pop bc
.result:
        ret z
        ld a,255
        ret
; A = joystick 1 lines (PSG R14 with R15 bit 6 = 0; 0 = pressed).
in_joystick:
        ld a,15
        out (0xa0),a
        in a,(0xa2)
        and 0xbf
        out (0xa1),a
        ld a,14
        out (0xa0),a
        in a,(0xa2)
        ret
in_stick_keys:
        db 0,7,1,8,5,6,0,7,3,0,2,1,4,5,3,0
in_stick_joy:
        db 0,1,5,0,7,8,6,7,3,2,4,3,0,1,5,0

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
        ld a,(0xc803)
        cp 17
        jr nz,.cpu_attack
        ld a,(0xc810)
        or a
        jr nz,.cpu_attack
        ld a,(0xc804)
        or a
        jr nz,.cpu_attack
        call combat_distance
        call player_kick_range
        jr nc,.cpu_attack
        ld hl,0xc80c
        dec (hl)
        ld a,25
        ld (0xc810),a
        ld (0xc80e),a          ; recovering instructor does not attack
        ld a,8
        ld (0xc820),a
        ld a,5                 ; arcade hit response moves five units
        ld (0xc822),a
        ld a,16                ; recovery movement after the initial recoil
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
        cp 24                   ; one hit opportunity per attack
        ret nz
        ld a,(0xc80f)
        or a
        ret nz
        ld a,(0xc804)
        or a
        ret nz
        call combat_distance
        cp 42
        ret nc
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
        cp 33                  ; arcade attack decision is distance-dependent
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
        ; Unlike the old prototype, a kick does not disable counterattacks.
        ld a,43                ; observed duration of this CPU kick
        ld (0xc80d),a
        xor a
        ld (0xc81a),a
        ld a,50
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
        ld a,128               ; raise/lower the knee around the kick
.pose_jump:
        ld (0xc300),a
        ld a,(0xc804)
        or a
        jr z,.ground
        ld a,128
        ld (0xc300),a
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
        jr .player_y
.ground:
        xor a
        ld (0xc80a),a
        ld a,(0xc803)
        or a
        jr nz,.ground_y
        ld a,(0xc819)
        or a
        jr z,.ground_y
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
        sub 16                 ; captured extended leg reaches left
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
        ld a,(0xc814)
        or a
        ret z
        ld (0xc817),a
        ld hl,result_template
        call copy_command
        ld a,(0xc817)
        cp 1
        jr z,.result_ready
        ld a,0x90              ; instructor message at VRAM y=912
        ld (0xc302),a
.result_ready:
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        jp command

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
        ld a,2
        ld (0xc82a),a
        ld a,5
        call ending_seconds
        ld a,2
        call ending_show
        ld a,2
        call ending_seconds
        ld a,3
        call ending_show
        call ending_half_second
        ld a,4
        call ending_show
        call ending_half_second
        ld a,5
        call ending_show
        call ending_half_second
        ld a,3
        ld (0xc82a),a
        ld a,3
        ld (0xc82b),a
.flag_loop:
        ld a,6
        call ending_show
        call ending_half_second
        ld a,7
        call ending_show
        call ending_half_second
        ld a,8
        call ending_show
        call ending_half_second
        ld hl,0xc82b
        dec (hl)
        jr nz,.flag_loop
        ld a,9
        call ending_show
        ld a,4
        ld (0xc82a),a
        call ending_rank_arrow
        call ending_rank_score
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
        ld a,(0xc82c)
        cp 6
        jr c,.new_scene
        cp 9
        jr nc,.new_scene
        ld a,(0xc836)
        or a
        jr z,.first_flag
        ; Consecutive flag frames share their palette. Upload the next one
        ; to the hidden page while the current frame remains on screen.
        ld a,1
        ld (0xc838),a
        ld a,(0xc837)
        xor 1
        ld (0xc837),a
        jr .load_data
.first_flag:
        ld a,1
        ld (0xc836),a
        xor a
        ld (0xc837),a
        ld (0xc838),a
        jr .blank
.new_scene:
        xor a
        ld (0xc836),a
        ld (0xc837),a
        ld (0xc838),a
.blank:
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
        ld a,(0xc838)
        or a
        jr nz,.same_palette
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ld bc,0x3061
        otir
        jr .vram_address
.same_palette:
        ld de,48
        add hl,de
.vram_address:
        xor a
        out (0x64),a
        out (0x63),a
        ld a,(0xc837)
        rrca
        out (0x63),a
        xor a
        out (0x63),a
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
        jr z,.uploaded
        ld a,(hl)
        inc hl
.emit:
        out (0x60),a
        djnz .emit
        jr .next_run
.uploaded:
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
        ld de,4                ; x=8
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
        ld b,8
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
ending_rank_rows: db 177,153,130,108,85

; Render a six-digit decimal score without altering the stored 24-bit total.
ending_rank_score:
        ld hl,(0xc75c)
        ld (0xc83a),hl
        ld a,(0xc75e)
        ld (0xc83c),a
        cp 15
        jr c,.score_ready
        jr nz,.score_limit
        ld de,0x4240           ; cap at 999999
        or a
        sbc hl,de
        jr c,.score_ready
.score_limit:
        ld hl,0x423f
        ld (0xc83a),hl
        ld a,15
        ld (0xc83c),a
.score_ready:
        xor a
        ld (0xc835),a
        ld ix,ending_divisors
.digit:
        xor a
        ld (0xc83d),a
.subtract:
        ld l,(ix+0)
        ld h,(ix+1)
        ex de,hl
        ld hl,(0xc83a)
        or a
        sbc hl,de
        ld a,(0xc83c)
        sbc a,(ix+2)
        jr c,.emit_digit
        ld (0xc83a),hl
        ld (0xc83c),a
        ld hl,0xc83d
        inc (hl)
        jr .subtract
.emit_digit:
        ld a,(0xc83d)
        call ending_score_digit
        inc ix
        inc ix
        inc ix
        ld hl,0xc835
        inc (hl)
        ld a,(hl)
        cp 6
        jr c,.digit
        ret

; A=digit, c835=column; write an 8x8 glyph at x=40+column*8, y=202.
ending_score_digit:
        push ix
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,ending_digits
        add hl,de
        push hl
        pop ix
        ld a,(0xc835)
        add a,a
        add a,a
        add a,20
        ld l,a
        ld h,101               ; 202*128 = $6500
        ld c,8
.row:
        xor a
        out (0x64),a
        ld a,l
        out (0x63),a
        ld a,h
        out (0x63),a
        xor a
        out (0x63),a
        ld b,4
.byte:
        ld a,(ix+0)
        out (0x60),a
        inc ix
        djnz .byte
        ld de,128
        add hl,de
        dec c
        jr nz,.row
        pop ix
        ret
ending_divisors:
        db 0xa0,0x86,0x01      ; 100000
        db 0x10,0x27,0x00      ; 10000
        db 0xe8,0x03,0x00      ; 1000
        db 0x64,0x00,0x00      ; 100
        db 0x0a,0x00,0x00      ; 10
        db 0x01,0x00,0x00      ; 1
; The arcade's squares of steps 7..3 (src/step7_visual.asm ending_map_cell).
ending_map_cell:
        dw 0,0,16,62,16,29
        db 0,0x0c,0xff,0xff,0x33,0x33,0,0,0x20
ending_arrow: incbin "../build/step7/rank-arrow.bin"
ending_digits: incbin "../build/step7/rank-digits.bin"
        include "../build/step7/ending.inc"

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
jump_heights:
        ; Ascent sampled from MAME; descent adjusted to land smoothly.
        db 5,9,14,18,22,25,28,31,34,36,38,40,41,42,42,42
        db 41,40,39,38,36,35,32,30,27,24,21,17,13,9,5,0,0
regs:   db 0x81,0,0x42,0
settings: db 0,0,0,0,0,0,0,0
palette: incbin "../build/step7/palette.bin"
        assert $ <= 0x8000
        ds 0x8000-$,0xff
        incbin "../build/step7/atlas0-rle-bank.bin"
        incbin "../build/step7/atlas1-rle-bank.bin"
        incbin "../build/step7/ending.bin"
