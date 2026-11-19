; The primary projectile is c8a0..a4, c8b2..b5, c8d5. Its second
; record lives at ca00..ca09. Swapping lets both share the existing physics,
; drawing and impact handling without duplicating the graphics or code.
mission_projectiles_tick:
        call mission_projectile_tick
        ld a,(0xca02)
        or a
        ret z
        call mission_projectile_swap_extra
        call mission_projectile_tick
        jp mission_projectile_swap_extra
mission_projectiles_draw:
        call mission_projectile_draw
        ld a,(0xca02)
        or a
        ret z
        call mission_projectile_swap_extra
        call mission_projectile_draw
        jp mission_projectile_swap_extra
mission_projectile_swap_extra:
        ld hl,0xc8a0
        ld de,0xca00
        ld b,5
        call .bytes
        ld hl,0xc8b2
        ld de,0xca05
        ld b,4
        call .bytes
        ld hl,0xc8d5
        ld de,0xca09
        ld b,1
.bytes:
        ld a,(de)
        ld c,(hl)
        ld (hl),a
        ld a,c
        ld (de),a
        inc de
        inc hl
        djnz .bytes
        ret
