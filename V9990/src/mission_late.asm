; Independent later orange thrower. Actor record c8e8..f3; c8e0 is its
; one-shot cue. Reuses the same projectile slot and sprite renderer.
mission_late_tick:
        ld a,(0xc856)
        or a
        ret z
        ld a,(0xc8e0)
        or a
        jr nz,.active
.check_spawn:
        ld hl,(0xc840)
        ld de,964
        or a
        sbc hl,de
        ret nc
        ld a,1
        ld (0xc8e0),a
        ld (0xc8e9),a
        ld hl,917
        ld (0xc8ea),hl
        xor a
        ld (0xc8ed),a
        ld (0xc8f0),a
.active:
        ld a,(0xc8e9)
        or a
        ret z
        cp 5
        ret nc
        ld hl,(0xc8ea)
        call mission_far_behind
        ret c                   ; left behind, off screen: waits (and is not drawn)
        call mission_swap_late
        ld a,2
        ld (0xc86f),a
        ld (0xc8ac),a
        ld a,1
        ld (0xc9a4),a          ; never walk away from the second crate
        call mission_enemy_tick
        call mission_swap_late
        xor a
        ld (0xc9a4),a
        ld (0xc86f),a
        ld (0xc8ac),a
        ret
mission_retire_old_bodies:
        ld a,(0xc8e0)
        or a
        ret z
        ld hl,0xc851
        call .retire
        ld hl,0xc871
        call .retire
        ld hl,0xc891
        call .retire
        ld hl,0xc8c1
        call .retire
        ld hl,0xc911
.retire:
        ld a,(hl)
        cp 4
        ret nz
        ld (hl),5
        ret

mission_late_draw:
        ld a,(0xc8e0)
        or a
        ret z
        ld a,(0xc8e9)
        or a
        ret z
        cp 5
        ret nc
        ld hl,(0xc8ea)
        call mission_far_behind
        ret c
        call mission_swap_late
        ld a,2
        ld (0xc86f),a
        ld a,1
        ld (0xc9a4),a          ; this fixed thrower uses the lower floor anchor
        call mission_draw_bottle_actor
        call mission_swap_late
        xor a
        ld (0xc9a4),a
        ld (0xc86f),a
        ret
mission_swap_late:
        ; Word exchanges without a loop: c850..c855, c85a..c85b and c858
        ; against the actor record at 0xc8e8.
        ld hl,(0xc850)
        ld de,(0xc8e8)
        ld (0xc8e8),hl
        ld (0xc850),de
        ld hl,(0xc852)
        ld de,(0xc8ea)
        ld (0xc8ea),hl
        ld (0xc852),de
        ld hl,(0xc854)
        ld de,(0xc8ec)
        ld (0xc8ec),hl
        ld (0xc854),de
        ld hl,(0xc85a)
        ld de,(0xc8f2)
        ld (0xc8f2),hl
        ld (0xc85a),de
        ld a,(0xc858)
        ld b,a
        ld a,(0xc8f0)
        ld (0xc858),a
        ld a,b
        ld (0xc8f0),a
        ret

; The right-side industrial reinforcement is an orange melee attacker.
mission_right_tick:
        ld a,(0xc871)
        cp 5
        ret nc
        call mission_enemy_swap
        ld a,(0xc8f4)
        or a
        ld a,1
        jr z,.kind
        ld a,2
.kind:
        ld (0xc86f),a
        call mission_enemy_tick
        call mission_enemy_swap
        xor a
        ld (0xc86f),a
        ld (0xc8ac),a
        ret
mission_right_draw:
        ld a,(0xc871)
        cp 5
        ret nc                 ; avoid swapping an already removed actor
        call mission_enemy_swap
        ld a,(0xc8f4)
        or a
        ld a,1
        jr z,.kind
        ld a,2
.kind:
        ld (0xc86f),a
        call mission_draw_enemy
        call mission_enemy_swap
        xor a
        ld (0xc86f),a
        ret

; Blue actor in the left slot becomes a knife thrower in the later scene.
mission_left_tick:
        ld a,(0xc8f5)
        or a
        jr z,.ordinary
        ld a,1
        ld (0xc8ac),a
        ld a,3
        ld (0xc86f),a
.ordinary:
        call mission_enemy_tick
        xor a
        ld (0xc8ac),a
        ld (0xc86f),a
        ret
mission_left_draw:
        ld a,(0xc8f5)
        or a
        jr z,.ordinary
        ld a,(0xc89c)
        cp 151
        jr c,.ordinary
        cp 171
        jr nc,.ordinary
        ld a,(0xc851)
        cp 1
        jr nz,.ordinary
        jp mission_draw_knife_throw
.ordinary:
        jp mission_draw_enemy
