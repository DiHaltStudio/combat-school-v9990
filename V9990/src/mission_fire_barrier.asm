; One persistent flame to the left of the second box. It becomes active
; as the nearby orange thrower enters the scene. World positions are provisional.
mission_fire_barrier_tick:
        ld a,(0xc856)
        or a
        ret z
        ld a,(0xc900)
        cp 2
        ret z                   ; replaced by a later bottle fire
        or a
        jr nz,.active
        ld a,(0xc8e0)
        or a
        ret z
        ld a,(0xc8e9)
        or a
        ret z
        ; The newly placed flame replaces an older dynamic ground fire,
        ; while leaving knives and bottles in flight alone.
        ld a,(0xc8a2)
        cp 2
        jr nz,.primary_clear
        xor a
        ld (0xc8a2),a
.primary_clear:
        ld a,(0xca02)
        cp 2
        jr nz,.secondary_clear
        xor a
        ld (0xca02),a
.secondary_clear:
        ld a,1
        ld (0xc900),a
.active:
        ld a,(0xc8dd)
        or a
        ret nz
        ld a,(0xc8d4)
        or a
        ret nz
        ld a,(0xc80a)
        cp 28
        ret nc
        ld hl,(0xc840)
        ld a,(0xc801)
        ld e,a
        ld d,0
        add hl,de
        ld de,24
        add hl,de
        push hl
        ld de,856
        or a
        sbc hl,de
        jr c,.third_fire
        ld de,32
        or a
        sbc hl,de
        jr c,.hit
.third_fire:
        pop hl
        ld a,(0xc990)
        bit 2,a
        ret z
        ld de,705
        or a
        sbc hl,de
        ret c
        ld de,32
        or a
        sbc hl,de
        ret nc
        jp mission_player_hit
.hit:
        pop hl
        jp mission_player_hit

mission_fire_barrier_draw:
        ld a,(0xc900)
        cp 1
        ret nz
        ld hl,872
        call .flame
        ld a,(0xc990)
        bit 2,a
        ret z
        ld hl,721
.flame:
        ; Clip the 32px flame at both screen edges so it enters gradually.
        ld de,(0xc840)
        or a
        sbc hl,de
        jr nc,.flame_center_visible
        ; A negative centre can still have visible pixels to its right.
        ld a,h
        cp 255
        ret nz
        ld a,l
        neg
        add a,8
        cp 32
        ret nc
        jr .clip_left
.flame_center_visible:
        ld a,h
        or a
        ret nz
        ld a,l
        cp 8
        jr nc,.flame_left_visible
        ld b,a
        ld a,8
        sub b
.clip_left:
        ld (0xc9a1),a
        ld b,a
        ld a,32
        sub b
        ld (0xc9a3),a
        xor a
        ld (0xc9a2),a
        jr .flame_command
.flame_left_visible:
        sub 8
        ld (0xc9a2),a
        ld b,a
        xor a
        ld (0xc9a1),a
        ld a,b
        cp 225
        ld a,32
        jr c,.flame_width_ready
        xor a
        sub b
.flame_width_ready:
        ld (0xc9a3),a
.flame_command:
        ld hl,mission_knife_template
        call copy_command
        ld a,(0xfc9e)           ; same two frames as bottle-created fire
        and 8
        add a,a
        add a,a
        add a,160
        ld b,a
        ld a,(0xc9a1)
        add a,b
        ld (0xc300),a
        ld a,160
        ld (0xc302),a
        ld a,11
        ld (0xc303),a
        ld a,(0xc9a2)
        ld (0xc304),a
        ld a,152
        ld (0xc306),a
        ld a,(0xc802)
        ld (0xc307),a
        ld a,(0xc9a3)
        ld (0xc308),a
        ld a,48
        ld (0xc30a),a
        ld hl,0xc300
        jp command
