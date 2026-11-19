; Final actors are independently clipped at the visible edge. The 64px
; atlas padding must not determine when an actor suddenly appears.
; The boss is static before activation; the president stays seated.
; C9B8 bits 0/1 mark separate restores intersecting boss/president bounds.
; Do not register static copies as dirty; restore them only when overwritten.
mission_final_invalidate:
        ; Separate dirty bits avoid repainting both actors for one overlap.
        ld a,h
        or a
        ret nz
        ld a,l
        cp 176
        ret nc
        ld a,(0xcf14)
        cp 200
        ret nc
        push hl
        push bc
        ld e,l
        add hl,bc
        ld c,255
        ld a,h
        or a
        jr nz,.end_ready
        ld c,l
.end_ready:
        ld a,(0xcf14)
        ld b,a
        ld a,(0xcf15)
        add a,b
        ld b,a
        ld d,0
        cp 137
        jr c,.done
        ld a,c
        cp 155
        jr c,.president
        set 0,d
.president:
        ld a,e
        cp 162
        jr nc,.done
        ld a,c
        cp 137
        jr c,.done
        ld a,b
        cp 155
        jr c,.done
        set 1,d
.done:
        ld a,(0xc9b8)
        or d
        ld (0xc9b8),a
        pop bc
        pop hl
        ret
mission_final_draw:
        ld a,(0xc9b8)
        or a
        ret z
        xor a
        ld (0xcf01),a
        call mission_final_render
        ld a,1
        ld (0xcf01),a
        ret
mission_final_render:
        ld a,(0xc841)
        or a
        ret nz
        ld a,(0xc981)
        or a
        jr nz,.president
        ld a,(0xc9b8)
        bit 0,a
        jr z,.president
        ld hl,154              ; boss origin 133 + opaque inset 21
        ld a,21
        ld bc,22*256+64        ; width / height
        ld d,0                 ; source Y inset
        call .actor
.president:
        ld a,(0xc9b8)
        bit 1,a
        ret z
        ld hl,136              ; president origin 117 + inset 19
        ld a,147               ; source X 128+19
        ld bc,26*256+46
        ld d,18
.actor:
        ld (0xc9b0),a
        ld a,d
        ld (0xc9b1),a
        push bc
        ld de,(0xc840)
        or a
        sbc hl,de
        pop bc
        jr nc,.positive
        ld a,h
        cp 255
        ret nz
        ld a,l
        neg
        cp b
        ret nc
        ld e,a
        ld a,b
        sub e
        ld b,a
        ld a,(0xc9b0)
        add a,e
        ld (0xc9b0),a
        ld l,0
        jr .visible
.positive:
        ld a,h
        or a
        ret nz
        ld a,l
        add a,b
        jr nc,.visible
        ld a,l
        neg
        ld b,a
.visible:
        push hl
        push bc
        ld hl,actor_template
        call copy_command
        pop bc
        pop hl
        ld a,l
        ld (0xc304),a
        ld a,b
        ld (0xc308),a
        ld a,c
        ld (0xc30a),a
        ld a,(0xc9b0)
        ld (0xc300),a
        ld a,(0xc9b1)
        add a,144
        ld (0xc302),a
        ld a,2
        ld (0xc303),a
        ld a,(0xc9b1)
        add a,136
        ld (0xc306),a
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        jp command
