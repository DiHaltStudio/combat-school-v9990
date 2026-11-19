; Approximate staircase height derived from the captured doorway. HL is the
; actor's world-space centre. The original collision tables remain untraced.
mission_floor_at_world:
        ld a,h
        cp 4
        jr c,.lower
        jr z,.lower
        cp 5
        jr nz,.level
        ld a,l
        cp 70                   ; 326
        jr nc,.level
        cp 48                   ; 304
        jr nc,.step1
        cp 24                   ; 280
        jr nc,.step2
        ld a,24                 ; 256..279
        ret
.lower:
        ld a,32
        ret
.step1:
        ld a,8
        ret
.step2:
        ld a,16
        ret
.level:
        xor a
        ret

mission_player_ground:
        ld a,(0xc8d4)
        or a
        jr z,.ground_level
        cp 2
        ld a,108                ; top of the second, slightly taller box
        ret z
        ld a,112                ; feet rest on the 24px-high crate stack
        ret
.ground_level:
        ld a,(0xc801)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld de,32
        add hl,de
        call mission_floor_at_world
        add a,104
        ret
