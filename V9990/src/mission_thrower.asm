; The first-room orange attacker is melee-only. Projectile code is retained
; for the later industrial scene, which has not yet been reconstructed.
; c890..c89b third actor; c89c throw cooldown; c8a0 projectile world x;
; c8a2 active; c8a3 direction (0 right, 1 left).
mission_third_tick:
        ld a,(0xc856)
        or a
        ret z
        ld a,(0xc841)
        cp 4                 ; camera threshold rebased by +256
        jr c,.check_molotov
        jr nz,.after_molotov
        ld a,(0xc840)
        cp 73                   ; player approaches the boxes from the right
        jr nc,.after_molotov
.check_molotov:
        call mission_molotov_spawn
.after_molotov:
        ld a,(0xc891)
        or a
        jr z,.waiting
        cp 5
        ret nc
        jr .active
.waiting:
        ld hl,(0xc840)
        ld de,1345              ; prior threshold + 768px of scenery
        or a
        sbc hl,de
        jr c,.active            ; still appear if the player bypasses the blues
        ld hl,(0xc840)
        ld de,1529
        or a
        sbc hl,de
        ret nc
        ld a,(0xc851)
        cp 2
        ret c
        ld a,(0xc871)
        cp 2
        ret c
.active:
        ld a,(0xc891)
        dec a
        cp 4
        jr nc,.awake            ; states 1..4: placed
        ld hl,(0xc892)
        call mission_far_behind
        ret c                   ; waits off screen behind the player
.awake:
        call mission_swap_third
        ld a,2
        ld (0xc86f),a
        ld a,(0xc8da)
        or a
        jr nz,.bottle_actor
        call mission_enemy_tick
        call mission_swap_third
        xor a
        ld (0xc86f),a
        ret
.bottle_actor:
        ld a,2
        ld (0xc8ac),a
        call mission_enemy_tick
        ld a,(0xc851)
        cp 1
        jr nz,.third_position_ready
        ld hl,(0xc8e2)         ; fixed position of the current bottle thrower
        ld (0xc852),hl
        xor a
        ld (0xc855),a          ; don't animate walking while stationary
.third_position_ready:
        call mission_swap_third
        xor a
        ld (0xc86f),a
        ld (0xc8ac),a
        ret

; Reuse the orange actor after the first-room encounter has finished.
; The new cue is approximate and is placed beyond the first crate stack.
mission_molotov_spawn:
        ld a,(0xc8da)
        or a
        ret nz
        ld a,(0xc891)
        or a
        jr z,.spawn_bottle
        cp 4
        ret c
.spawn_bottle:
        ld a,1
        ld (0xc8da),a
        ld (0xc891),a
        ld hl,1076               ; enemy waits beyond the first crate stack
        ld (0xc8e2),hl
        ld (0xc892),hl
        xor a
        ld (0xc895),a
        ld (0xc898),a
        ld a,4                  ; first bottle arrives while still off screen
        ld (0xc8dc),a
        ret

; Draw the captured release pose briefly after a bottle leaves the hand.
mission_draw_bottle_actor:
        ld a,(0xc851)
        cp 1
        jr nz,.normal
        ld a,(0xc8dc)
        cp 145
        jr c,.normal
        cp 161
        jr nc,.normal
        ld a,1
        ld (0xc9a5),a
        call mission_draw_enemy
        xor a
        ld (0xc9a5),a
        ret
.normal:
        jp mission_draw_enemy

mission_third_draw:
        ld a,(0xc891)
        or a
        ret z
        cp 5
        ret nc
        ld hl,(0xc892)
        call mission_far_behind
        ret c                   ; off screen: nothing to draw
        call mission_swap_third
        ld a,2
        ld (0xc86f),a
        ld a,(0xc8da)
        or a
        jr z,.draw_melee
        call mission_draw_bottle_actor
        jr .draw_done
.draw_melee:
        call mission_draw_enemy
.draw_done:
        call mission_swap_third
        xor a
        ld (0xc86f),a
        ret

mission_swap_third:
        ; Word exchanges without a loop: c850..c855, c85a..c85b and c858
        ; against the actor record at 0xc890.
        ld hl,(0xc850)
        ld de,(0xc890)
        ld (0xc890),hl
        ld (0xc850),de
        ld hl,(0xc852)
        ld de,(0xc892)
        ld (0xc892),hl
        ld (0xc852),de
        ld hl,(0xc854)
        ld de,(0xc894)
        ld (0xc894),hl
        ld (0xc854),de
        ld hl,(0xc85a)
        ld de,(0xc89a)
        ld (0xc89a),hl
        ld (0xc85a),de
        ld a,(0xc858)
        ld b,a
        ld a,(0xc898)
        ld (0xc858),a
        ld a,b
        ld (0xc898),a
        ret

; Preserve the existing projectile code while providing a second independent
; slot. Both records are updated and drawn through the same collision code.
mission_try_throw:
        ld a,(0xc8ac)
        or a
        ret z
        cp 2
        ld hl,0xc89c
        jr nz,.check_cooldown
        ld hl,0xc8dc
.check_cooldown:
        ld a,(hl)
        or a
        jr z,.select_slot
        ld a,(0xc8ac)
        cp 1
        jp nz,mission_try_throw_core
        ld a,(hl)
        cp 159                  ; the core releases on the following decrement
        jp nz,mission_try_throw_core
.select_slot:
        ld a,(0xc8a2)
        or a
        jp z,mission_try_throw_core
        call mission_projectile_swap_extra
        call mission_try_throw_core
        jp mission_projectile_swap_extra
mission_try_throw_core:
        ld a,(0xc8ac)
        or a
        ret z                   ; first-room orange attackers do not throw
        cp 2
        ld hl,0xc89c
        jr nz,.cooldown_selected
        ld hl,0xc8dc            ; the two throwers have independent cadence
.cooldown_selected:
        ld a,(hl)
        or a
        jr z,.ready
        dec (hl)
        ld a,(0xc8ac)
        cp 1
        ret nz
        ld a,(hl)
        cp 158                  ; release halfway through the gesture
        jr z,.launch
        ret
.ready:
        ld a,(0xc8a2)
        or a
        ret nz
        ld hl,(0xc85e)
        ld a,h
        or a
        ret nz
        ld a,l
        cp 40
        ret c
        cp 145
        ret nc
        ld a,(0xc8ac)
        cp 1
        jr nz,.launch
        ld a,170                ; countdown includes wind-up and cooldown
        ld (0xc89c),a
        ret
.launch:
        ld a,(0xc8a2)
        or a
        ret nz                  ; never replace another projectile or fire
        ld hl,(0xc852)
        ld a,(0xc85a)
        or a
        ld de,44                ; projectile starts at the outstretched hand
        jr z,.throw_origin_ready
        ld de,4
.throw_origin_ready:
        add hl,de
        ld (0xc8a0),hl
        ld hl,(0xc852)
        ld de,32
        add hl,de
        call mission_floor_at_world
        ld b,a
        ld a,(0xc8ac)
        cp 1
        ld a,b
        jr nz,.bottle_height
        add a,118               ; knife leaves the raised throwing arm
        jr .height_selected
.bottle_height:
        add a,137
.height_selected:
        ld (0xc8b2),a
        ld a,(0xc8ac)
        cp 2
        ld a,0                  ; knife travels initially level
        jr nz,.throw_speed_ready
        ld a,252                ; bottle rises more before falling
.throw_speed_ready:
        ld (0xc8b3),a
        xor a
        ld (0xc8b4),a
        ld a,(0xc85a)
        ld (0xc8a3),a
        ld a,(0xc8ac)
        ld (0xc8d5),a           ; 1 knife, 2 flaming bottle
        ld a,1
        ld (0xc8a2),a
        ld a,(0xc8ac)
        cp 1
        ld a,160               ; bottles have a longer pause between throws
        jr nz,.cooldown_ready
        ld a,157                ; follow-through, then a longer pause
.cooldown_ready:
        ld b,a
        ld a,(0xc8ac)
        cp 2
        ld a,b
        jr z,.bottle_cooldown
        ld (0xc89c),a
        ret
.bottle_cooldown:
        ld (0xc8dc),a
        ret

mission_projectile_tick:
        ld a,(0xc8a2)
        or a
        ret z
        cp 2
        jp z,.fire_tick
        ld a,(0xc856)
        or a
        jp z,.remove
        ld a,(0xc8b3)
        ld b,a
        ld a,(0xc8b2)
        add a,b
        cp 210
        jp nc,.land_or_remove
        ld (0xc8b2),a
        ld a,(0xc8d5)
        cp 2
        jr nz,.airborne
        ld a,b
        bit 7,a
        jr nz,.airborne
        ld hl,(0xc8a0)
        call mission_floor_at_world
        add a,160
        ld b,a
        ld a,(0xc8b2)
        cp b
        jp nc,.ignite
.airborne:
        ld a,(0xc8d5)
        cp 1
        jr z,.height_ready       ; knives travel straight; bottles fall
        ld hl,0xc8b4
        inc (hl)
        ld a,(hl)
        and 3
        jr nz,.height_ready
        ld hl,0xc8b3
        ld a,(hl)
        cp 4
        jr z,.height_ready
        inc (hl)
.height_ready:
        ld hl,(0xc8a0)
        ld a,(0xc8a3)
        or a
        jr nz,.left
        ld de,4
        ld a,(0xc8d5)
        cp 2
        jr nz,.right_speed_ready
        dec de
        dec de
        ld a,(0xc8b4)
        and 3
        jr nz,.right_speed_ready
        inc de                  ; alternate speed keeps the same landing point
.right_speed_ready:
        add hl,de
        jr .moved
.left:
        ld de,4
        ld a,(0xc8d5)
        cp 2
        jr nz,.left_speed_ready
        dec de
        dec de
        ld a,(0xc8b4)
        and 3
        jr nz,.left_speed_ready
        inc de
.left_speed_ready:
        or a
        sbc hl,de
        jr c,.remove
.moved:
        ld (0xc8a0),hl
        ld de,(0xc840)
        or a
        sbc hl,de
        jr c,.remove
        ld a,h
        or a
        jr nz,.remove
        ld a,l
        cp 241
        jr nc,.remove
        ld a,(0xc801)
        add a,24
        ld e,a
        ld d,0
        or a
        sbc hl,de
        jr c,.projectile_left
        xor a                   ; projectile is to the player's right
        ld (0xc8d9),a
        jr .distance
.projectile_left:
        ld a,1
        ld (0xc8d9),a
        ld hl,(0xc840)
        ld a,(0xc801)
        ld e,a
        ld d,0
        add hl,de
        ld de,24
        add hl,de
        ld de,(0xc8a0)
        or a
        sbc hl,de
.distance:
        ld a,h
        or a
        ret nz
        ld a,l
        cp 32
        ret nc
        push af
        ld a,(0xc8d5)
        cp 1                    ; a kick destroys knives, not bottles
        jr nz,.body_collision
        ld a,(0xc803)
        cp 5
        jr c,.body_collision
        cp 25
        jr nc,.body_collision
        ld a,(0xc809)
        ld b,a
        ld a,(0xc8d9)
        cp b
        jr nz,.body_collision
        call mission_projectile_vertical_distance
        cp 20
        jr nc,.body_collision
        pop af
        jp .remove
.body_collision:
        pop af
        cp 9
        ret nc
        ; Compare the actual arc height with the player's moving body.
        call mission_projectile_vertical_distance
        cp 20
        ret nc
        call mission_player_hit
.remove:
        xor a
        ld (0xc8a2),a
        ret

.land_or_remove:
        ld a,(0xc8d5)
        cp 2
        jr nz,.remove
.ignite:
        ; The new ground fire replaces an older one, while knives and bottles
        ; in flight remain independent. During secondary updates the records
        ; are swapped, so ca02 always refers to the other projectile.
        ld a,(0xca02)
        cp 2
        jr nz,.old_dynamic_cleared
        xor a
        ld (0xca02),a
.old_dynamic_cleared:
        ld a,(0xc900)
        cp 1
        jr nz,.barrier_cleared
        ld hl,(0xc8a0)
        ld de,981
        or a
        sbc hl,de
        jr nc,.barrier_cleared   ; first crate does not erase later obstacle
        ; Keep the initial obstacle until the camera has reached it, but do
        ; not suppress a bottle's own fire when it lands before that point.
        ld hl,(0xc840)
        ld de,888
        or a
        sbc hl,de
        jr nc,.barrier_cleared
        ld a,2
        ld (0xc900),a
.barrier_cleared:
        ld hl,(0xc8a0)
        call mission_floor_at_world
        add a,160
        ld (0xc8b2),a
        ld a,2
        ld (0xc8a2),a
        ld a,160                ; fire remains visible for several seconds
        ld (0xc8b5),a
        ret
.fire_tick:
        ld a,(0xc856)
        or a
        jr z,.remove
        ld hl,0xc8b5
        dec (hl)
        jr nz,.fire_active
        ld a,180                ; clear passage after the flames go out
        ld (0xc8dc),a
        jr .remove
.fire_active:
        ld a,(0xc8dd)
        or a
        ret nz                  ; hanging above the flames
        ld a,(0xc8d4)
        or a
        ret nz                  ; the top of the stack is above ground fire
        ld a,(0xc80a)
        cp 28
        ret nc                  ; jumping clears the low flames
        ld hl,(0xc840)
        ld a,(0xc801)
        ld e,a
        ld d,0
        add hl,de
        ld de,24
        add hl,de
        ld de,(0xc8a0)
        or a
        sbc hl,de
        jr nc,.fire_distance
        or a
        ex de,hl
        ld hl,0
        sbc hl,de
.fire_distance:
        ld a,h
        or a
        ret nz
        ld a,l
        cp 16
        ret nc
        call mission_player_hit
        jp .remove

; Absolute vertical difference between the projectile and the player.
mission_projectile_vertical_distance:
        ld a,(0xc8dd)
        or a
        jr z,.standing_height
        ld a,81                 ; sprite top while hanging from the lower pipe
        jr .height_ready
.standing_height:
        call mission_player_ground
.height_ready:
        add a,28
        ld b,a
        ld a,(0xc80a)
        ld c,a
        ld a,b
        sub c
        ld b,a
        ld a,(0xc8b2)
        add a,4
        sub b
        jr nc,.vertical_distance
        neg
.vertical_distance:
        ret

mission_player_hit:
        ld a,(0xc801)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld a,112
        call mission_start_impact
        xor a
        ld (0xc856),a
        ld (0xc818),a
        ld a,100
        ld (0xc857),a
        ld a,60
        ld (0xc823),a
        ret

mission_projectile_draw:
        ld a,(0xc8a2)
        or a
        ret z
        ld hl,(0xc8a0)
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
        ld (0xc8a4),a
        ld hl,mission_knife_template
        call copy_command
        ld a,(0xc8a3)
        or a
        ld a,0
        jr z,.source
        ld a,16
.source:
        ld b,a
        ld a,(0xc8a2)
        cp 2
        jr nz,.flying_source
        ; Center the wider fire over the bottle's impact point and anchor its
        ; base at the same ground height as the earlier small flame.
        ld a,(0xc8a4)
        cp 8
        ret c
        cp 233
        ret nc
        sub 8
        ld (0xc8a4),a
        ld a,(0xfc9e)           ; one copy per fire, alternate every 8 ticks
        and 8
        add a,a
        add a,a
        add a,160
        ld (0xc300),a
        ld a,160
        ld (0xc302),a          ; fire graphic at atlas y=2976
        ld a,11
        ld (0xc303),a
        ld a,32
        ld (0xc308),a
        ld a,48
        ld (0xc30a),a
        jr .destination
.flying_source:
        ld a,(0xc8d5)
        cp 2
        ld a,b
        jr nz,.source_ready
        add a,128
        ld b,a
        ld a,160                ; captured 16x16 bottle at atlas y=2976
        ld (0xc302),a
        ld a,11
        ld (0xc303),a
        ld a,16
        ld (0xc30a),a
        ld a,b
.source_ready:
        ld (0xc300),a
.destination:
        ld a,(0xc8a4)
        ld (0xc304),a
        ld a,(0xc8b2)
        ld b,a
        ld a,(0xc8a2)
        cp 2
        ld a,b
        jr nz,.destination_y_ready
        sub 40
.destination_y_ready:
        ld (0xc306),a
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        jp command

mission_knife_template:
        dw 0,2880,0,137,16,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
