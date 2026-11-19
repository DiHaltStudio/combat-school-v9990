; Industrial assailants appear sequentially to reduce rendering load.
; c990 is a bitset of one-shot appearances; positions remain approximate.
mission_later_encounters_tick:
        ld a,(0xc856)
        or a
        ret z
        ld a,(0xc900)
        or a
        ret z
        ; One encounter behind the second-crate attacker. Once defeated it
        ; is never respawned, and no further reinforcements are introduced.
        ld a,(0xc990)
        bit 0,a
        jr nz,.actors
        ld hl,(0xc840)
        ld de,786
        or a
        sbc hl,de
        jr nc,.actors
        ld a,(0xc990)
        set 0,a
        ld (0xc990),a
        ld ix,0xc940
        ld hl,766
        call mission_later_spawn
.actors:
        call mission_exit_encounters_tick
        ld a,1
        ld (0xc9a4),a           ; the bottle thrower keeps its post: its fires
        ld ix,0xc940            ; stay away from the doorway (frame time)
        ld a,2
        call mission_later_actor
        xor a
        ld (0xc9a4),a
        ld a,(0xc941)
        or a
        ret z
        cp 5
        ret nc
        ; The preceding orange attacker stays between the second box and
        ; the third stack. Origins include the shared 32-pixel foot anchor.
        ld hl,(0xc942)
        ld de,680               ; centre 712: right side of the third stack
        or a
        sbc hl,de
        jr nc,.upper_limit
        ld (0xc942),de
        xor a
        ld (0xc945),a          ; stop walking animation against the obstacle
        ret
.upper_limit:
        add hl,de
        ld de,886               ; centre 918: left side of the second box
        or a
        sbc hl,de
        ret c
        ret z
        ld (0xc942),de
        xor a
        ld (0xc945),a          ; stop walking animation against the obstacle
        ret
mission_later_actor:
        push af
        ld a,(ix+1)
        or a
        jr z,.skip
        cp 5
        jr nc,.skip
        ld l,(ix+2)
        ld h,(ix+3)
        call mission_far_behind
        jr c,.skip              ; waits off screen behind the player
        call mission_later_swap
        pop af
        cp 4                  ; orange melee: colour and weapon are independent
        jr nz,.weapon_ready
        xor a
        ld (0xc8ac),a
        ld a,2
        jr .type
.weapon_ready:
        ld (0xc8ac),a
        or a
        jr z,.type
        cp 1
        ld a,2
        jr nz,.type
        ld a,3
.type:
        ld (0xc86f),a
        call mission_enemy_tick
        call mission_later_swap
        xor a
        ld (0xc86f),a
        ld (0xc8ac),a
        ret
.skip:
        pop af
        ret
; HL = an actor's x (its 64-pixel sprite origin): CF when it is at least
; 16 pixels past the right edge of the screen, behind the player. Such an
; actor neither thinks nor is drawn (it waits there, as the arcade's
; enemies left behind; the camera can come back and wake it). Saves the
; frame time of up to four AI ticks in the industrial area. Keeps BC, IX.
mission_far_behind:
        ld de,(0xc840)
        or a
        sbc hl,de
        jr c,.no                ; left of the camera: ahead of the player
        ld de,256+16
        sbc hl,de               ; CF clear here
        ccf
        ret
.no:
        or a
        ret

mission_later_spawn:
        ld (ix+1),1
        ld (ix+2),l
        ld (ix+3),h
        xor a
        ld (ix+4),a
        ld (ix+5),a
        ld (ix+8),a
        ld (ix+10),a
        ld (ix+11),a
        ld a,80
        ld (ix+12),a
        ld (ix+13),a
        ret
mission_later_encounters_draw:
        call mission_exit_encounters_draw
        ld a,(0xc990)
        bit 0,a
        ret z
        ld ix,0xc940
        ld a,2
mission_later_draw_actor:
        push af
        ld a,(ix+1)
        or a
        jr z,.skip
        cp 5
        jr nc,.skip
        ld l,(ix+2)
        ld h,(ix+3)
        call mission_far_behind
        jr c,.skip              ; off screen: nothing to draw
        call mission_later_draw_swap
        pop af
        ld (0xc86f),a
        cp 3
        jr nz,.normal
        ld a,(0xc89c)
        cp 151
        jr c,.normal
        cp 171
        jr nc,.normal
        ld a,(0xc851)
        cp 1
        jr nz,.normal
        call mission_draw_knife_throw
        jr .done
.normal:
        ld a,(0xc86f)
        cp 2
        jr nz,.normal_blue
        call mission_draw_bottle_actor
        jr .done
.normal_blue:
        call mission_draw_enemy
.done:
        call mission_later_draw_swap
        xor a
        ld (0xc86f),a
        ret
.skip:
        pop af
        ret
mission_later_swap:
        call mission_knife_pair_swap
        ld a,(0xc8dc)
        ld b,a
        ld a,(ix+13)
        ld (0xc8dc),a
        ld (ix+13),b
        ret

; Explicit, one-shot exit encounters. Keep C940 alive so a surviving
; orange attacker remains between the crates; never replace that record.
; C950 knife thrower, C970 chain assailant inside brick room. (The orange
; guard beside the thrower, C960, is left out: with the C940 attacker still
; there, three assailants took the frame past its time.)
mission_exit_encounters_tick:
        ld a,(0xc990)
        bit 4,a
        jr nz,.room
        ld hl,(0xc840)
        ld de,556
        or a
        sbc hl,de
        ret nc
        ld a,(0xc990)
        bit 4,a
        jr nz,.room
        set 4,a
        ld (0xc990),a
        ld ix,0xc950
        ld hl,481               ; knife thrower in the doorway, clear of its post (477..500)
        call mission_later_spawn
.room:
        ; Arcade (record $0c90, tools/mame_mission_chain_capture.lua): the
        ; chain assailant appears when the camera reaches 173 (ROM 272),
        ; centre X 161 (ROM 260), 12 px outside the left edge, and walks in.
        ld hl,(0xc840)
        ld de,272
        or a
        sbc hl,de
        jr nc,.update
        ld a,(0xc990)
        bit 5,a
        jr nz,.update
        set 5,a
        ld (0xc990),a
        ld ix,0xc970
        ld hl,260-32            ; sprite origin: centre 260
        call mission_later_spawn
        xor a
        ld (0xc97e),a
        ld (0xc97f),a
        ld (0xc97c),a
        ld (0xc977),a
.update:
        ld a,1
        ld (0xc9a4),a           ; doorway guards turn/attack but never pursue
        ld ix,0xc950
        ld a,1
        call mission_later_actor
        xor a
        ld (0xc9a4),a
        jp mission_chain_tick
mission_exit_encounters_draw:
        ld a,(0xc990)
        bit 4,a
        ret z
        ld ix,0xc950
        ld a,3
        call mission_later_draw_actor
        jp mission_chain_draw

; Rendering does not need hit latches or projectile cooldowns. Exchange only
; state, position, animation and facing, retaining the gameplay record.
mission_later_draw_swap:
        push ix
        pop de
        inc de
        ld hl,0xc851
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc de
        inc hl
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc de
        inc hl
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc de
        inc hl
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc de
        inc hl
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc de
        inc hl
        ld a,(0xc85a)
        ld b,a
        ld a,(ix+10)
        ld (0xc85a),a
        ld (ix+10),b
        ld a,(0xc89c)
        ld b,a
        ld a,(ix+12)
        ld (0xc89c),a
        ld (ix+12),b
        ld a,(0xc8dc)
        ld b,a
        ld a,(ix+13)
        ld (0xc8dc),a
        ld (ix+13),b
        ret
