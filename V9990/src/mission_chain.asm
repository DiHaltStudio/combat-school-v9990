; Chain assailant, separate from the large final boss.
; C970 record: +1 state (1 walk,2 attack,3 hurt,4 falling,5 down),
; +2 world sprite origin, +4 timer, +5 walk phase, +8 facing,
; +10 kick latch, +11 movement oscillator, +12 fractional step,
; +7 post-strike pause, +14 accepted hits, +15 pose. Scratch C9B2..C9B6.
; Arcade B2B4/B30F/B347/B388: first impact wounds, second defeats,
; +500 each, extended collision only during the chain strike.
; User-requested balance: three effective hits and 48 idle frames after
; each strike. The arcade observation above is kept as separate evidence.
mission_chain_tick:
        ld a,(0xc971)
        or a
        ret z
        cp 5
        ret nc
        ld a,(0xc856)
        or a
        ret z
        ld a,(0xc803)
        or a
        jr nz,.latch
        ld (0xc97a),a
.latch:
        ld a,(0xc971)
        cp 3
        jp nc,.reaction
        ld a,(0xc823)
        or a
        ret nz
        ld a,(0xc801)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld (0xc9b4),hl
        ld de,(0xc972)
        or a
        sbc hl,de
        ld a,0
        jr nc,.distance
        xor a
        sub l
        ld l,a
        ld a,0
        sbc a,h
        ld h,a
        ld a,1
.distance:
        ld (0xc9b6),a           ; current direction towards the player
        ld (0xc9b2),hl
        ld a,(0xc971)
        cp 2
        jr z,.kick
        ld a,(0xc9b6)
        ld (0xc978),a
.kick:
        ld a,h
        or a
        jp nz,.behaviour
        ld a,l
        cp 33                   ; arcade kick reach, as for the other assailants
        jp nc,.behaviour
        ld a,(0xc8dd)
        or a
        jp nz,.behaviour
        ld a,(0xc8d4)
        or a
        jp nz,.behaviour
        ld a,(0xc97a)
        or a
        jp nz,.behaviour
        ld a,(0xc803)
        cp 5
        jp c,.behaviour
        cp 25
        jp nc,.behaviour
        ld a,(0xc809)
        xor 1
        ld b,a
        ld a,(0xc9b6)
        cp b
        jp nz,.behaviour
        ld a,(0xc804)
        or a
        jr z,.hit
        ld a,(0xc803)
        cp 19
        jp c,.behaviour
        ld a,(0xc80a)
        cp 49
        jp nc,.behaviour
.hit:
        ld a,1
        ld (0xc97a),a
        ld hl,0xc97e
        inc (hl)
        ld a,(hl)
        cp 3
        ld a,3
        ld b,26
        jr c,.hurt
        ld a,4
        ld b,64
.hurt:
        ld (0xc971),a
        ld a,b
        ld (0xc974),a
        ld a,6
        ld (0xc97f),a
        ld hl,(0xc972)
        ld a,96
        call mission_start_impact
        ld hl,(0xc75c)
        ld de,500
        add hl,de
        ld (0xc75c),hl
        ld a,(0xc75e)
        adc a,0
        ld (0xc75e),a
        ret
.reaction:
        ld hl,0xc974
        dec (hl)
        jr z,.reaction_done
        ld a,(0xc971)
        cp 4
        ret nz
        ld a,(hl)
        cp 40
        ret nc
        ld a,7
        ld (0xc97f),a
        ret
.reaction_done:
        ld a,(0xc971)
        cp 4
        ld a,1
        ld b,2
        jr nz,.reaction_save
        ld a,5
        ld b,8
.reaction_save:
        ld (0xc971),a
        ld a,b
        ld (0xc97f),a
        ret
.behaviour:
        ld a,(0xc971)
        cp 2
        jp z,.attack
        ld hl,0xc977
        ld a,(hl)
        or a
        jr z,.pause_done
        dec (hl)
        ld a,2
        ld (0xc97f),a           ; stationary and vulnerable while recovering
        ret
.pause_done:
        ld hl,(0xc9b2)
        ld a,h
        or a
        jr nz,.walk
        ld a,l
        cp 56
        jr nc,.walk
        ld a,2
        ld (0xc971),a
        ld a,36
        ld (0xc974),a
        ld a,3
        ld (0xc97f),a
        ret
.walk:
        ; 8.8 magnitudes from B2EC: approach +0.5, retreat -0.75.
        ld hl,0xc975
        inc (hl)
        ld a,(hl)
        and 8
        rrca
        rrca
        rrca
        ld (0xc97f),a
        ld a,(0xc97b)
        add a,2
        ld (0xc97b),a
        cp 192
        ld b,128
        ld a,(0xc978)
        jr c,.step
        xor 1
        ld b,192
.step:
        ld c,a
        ld a,(0xc97c)
        add a,b
        ld (0xc97c),a
        ret nc
        ld hl,(0xc972)
        ld a,c
        or a
        jr nz,.left
        inc hl
        jr .save
.left:
        dec hl
.save:
        ld (0xc972),hl
        ret
.attack:
        ld hl,0xc974
        dec (hl)
        jr z,.attack_done
        ld a,(hl)
        cp 28
        ld b,3                  ; raise the chain
        jr nc,.pose
        cp 20
        ld b,4                  ; extend: the only damaging pose
        jr nc,.pose
        cp 12
        ld b,5
        jr nc,.pose
        ld b,2
.pose:
        ld a,b
        ld (0xc97f),a
        cp 4
        ret nz
        ld a,(0xc9b6)
        ld b,a
        ld a,(0xc978)
        cp b
        ret nz                  ; no hit behind an attack already in progress
        ld hl,(0xc9b2)
        ld a,h
        or a
        ret nz
        ld a,l
        cp 55                   ; 48px chain plus player's small body radius
        ret nc
        ld a,(0xc8dd)
        or a
        ret nz
        ld a,(0xc8d4)
        or a
        ret nz
        ld a,(0xc80a)
        cp 33
        ret nc
        ld a,(0xc857)
        or a
        ret nz
        jp mission_player_hit
.attack_done:
        ld a,48                ; about 0.8 seconds at 60 Hz to close the gap
        ld (0xc977),a
        ld a,1
        ld (0xc971),a
        ld a,2
        ld (0xc97f),a
        ret

; Two tightly cropped copies, packed in unused background-strip tails.
; Descriptors: source x/y words, width/height, signed world dx, screen dy.
; Each pose occupies 24 descriptor bytes: two pieces and their union bounds.
; C9BA holds the shared world anchor, C9BE selects copy versus dirty marking.
; Source and destination are clipped together at both viewport edges.
mission_chain_draw:
        ld a,(0xc971)
        or a
        ret z
        ld hl,(0xc972)
        ld (0xc9ba),hl
        ld a,(0xc97f)
        add a,a
        ld b,a
        ld a,(0xc978)
        add a,b
        ld de,mission_chain_poses
mission_pose_draw:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        push hl
        pop bc
        add hl,hl
        add hl,bc
        add hl,de
        push hl
        pop ix
        xor a
        ld (0xcf01),a
        ld (0xc9be),a
        ld b,2
.piece_loop:
        push bc
        push ix
        call .piece
        pop ix
        ld de,8
        add ix,de
        pop bc
        djnz .piece_loop
        ld a,1
        ld (0xcf01),a
        ld (0xc9be),a
        ; One union rectangle restores both halves on the hidden page.
        jp .piece
.piece:
        ld a,(ix+4)
        or a
        ret z
        ld hl,actor_template
        call copy_command
        ld l,(ix+0)
        ld h,(ix+1)
        ld (0xc300),hl
        ld l,(ix+2)
        ld h,(ix+3)
        ld (0xc302),hl
        ld a,(ix+4)
        ld (0xc308),a
        ld a,(ix+5)
        ld (0xc30a),a
        ld a,(ix+7)
        add a,136
        ld (0xc306),a
        ld a,(0xc802)
        ld (0xc307),a
        ld e,(ix+6)
        ld d,0
        bit 7,e
        jr z,.offset
        dec d
.offset:
        ld hl,(0xc9ba)
        add hl,de
        ld de,(0xc840)
        or a
        sbc hl,de
        jr nc,.positive
        ld a,h
        cp 255
        ret nz
        ld a,l
        neg
        ld b,a
        ld a,(0xc308)
        sub b
        ret c
        ret z
        ld (0xc308),a
        ld a,(0xc300)
        add a,b
        ld (0xc300),a
        ld l,0
        jr .visible
.positive:
        ld a,h
        or a
        ret nz
        ld a,(0xc308)
        add a,l
        jr nc,.visible
        ld a,l
        neg
        ld (0xc308),a
.visible:
        ld a,l
        ld (0xc304),a
        ld a,(0xc9be)
        or a
        ld hl,0xc300
        jp z,command
        ld a,(0xc304)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld (0xcf18),hl
        jp mission_ring_record
