; One blue knife thrower beyond the first bottle attacker.
; Actor records at c910 and c920; bit flag c930 tracks their entrance.
mission_knife_pair_tick:
        ld a,(0xc856)
        or a
        ret z
        ld a,(0xc930)
        or a
        jr nz,.active
        ld hl,(0xc840)
        ld de,1026
        or a
        sbc hl,de
        ret nc
        ld a,1
        ld (0xc930),a
        ld (0xc911),a
        ld hl,1016
        ld (0xc912),hl
        xor a
        ld (0xc915),a
        ld (0xc918),a
        ld a,90
        ld (0xc91c),a
.active:
        ld ix,0xc910
        jp mission_knife_pair_actor
mission_knife_pair_actor:
        ld a,(ix+1)
        or a
        ret z
        cp 5
        ret nc
        call mission_knife_pair_swap
        ld a,3
        ld (0xc86f),a
        ld a,1
        ld (0xc8ac),a
        call mission_enemy_tick
        call mission_knife_pair_swap
        xor a
        ld (0xc86f),a
        ld (0xc8ac),a
        ret
mission_knife_pair_draw:
        ld a,(0xc930)
        or a
        ret z
        ld ix,0xc910
.draw_one:
        ld a,(ix+1)
        or a
        ret z
        cp 5
        ret nc
        call mission_knife_pair_swap
        ld a,3
        ld (0xc86f),a
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
        call mission_draw_enemy
.done:
        call mission_knife_pair_swap
        xor a
        ld (0xc86f),a
        ret
mission_knife_pair_swap:
        push ix
        pop de
        ld hl,0xc850
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc hl
        inc de
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc hl
        inc de
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc hl
        inc de
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc hl
        inc de
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc hl
        inc de
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc hl
        inc de
        ld hl,0xc858
        push ix
        pop de
        ld a,e
        add a,8
        ld e,a
        call .one
        ld hl,0xc85a
        inc de
        inc de
        call .one
        inc hl
        inc de
        call .one
        ld hl,0xc89c
        inc de
.one:
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        ret
