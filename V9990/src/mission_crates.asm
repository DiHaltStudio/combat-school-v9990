; Approximate first crate stack: collision interval and top surface are
; derived from the captured background, pending arcade collision tracing.
; c8d4: standing on the crates; c8d6..d7: previous player screen position.
mission_save_position:
        ld hl,(0xc800)
        ld (0xc8d6),hl
        ret

mission_crates_tick:
        ld a,(0xc856)
        or a
        ret z
        ld a,(0xc801)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld de,32                ; centre of the anchored player sprite
        add hl,de
        ld a,h
        cp 2
        jp z,.third_crates
        cp 3
        jp z,.second_crate
        cp 4
        jr nz,.outside
        ld a,l
        ld b,a
        ld a,(0xc8d4)
        or a
        jr z,.not_on_top
        ld a,(0xc804)
        or a
        ret nz                  ; preserve takeoff height while airborne
        ld a,b
        cp 105
        jr c,.leave_top
        cp 177
        ret c
.leave_top:
        xor a
        ld (0xc8d4),a
        ret
.not_on_top:
        ld a,b
        cp 105
        jr c,.side_check
        cp 177
        jr nc,.side_check
        ld a,(0xc804)
        or a
        jr z,.side_check
        cp 20                   ; descending half of the sampled jump
        jr nc,.side_check
        ld a,(0xc80a)
        cp 25
        jr nc,.side_check
        ld a,1
        ld (0xc8d4),a
        xor a
        ld (0xc804),a
        ld (0xc808),a
        ret
.side_check:
        ld a,b
        cp 93
        ret c
        cp 189
        ret nc
        ld a,(0xc80a)
        cp 24
        ret nc                  ; jump is high enough to enter over the stack
        ; After walking off the top the centre is still within the wider
        ; side-collision margin. Allow motion outwards, never back into it.
        ld a,(0xc8d7)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld de,32
        add hl,de
        ld a,h
        cp 4
        jr nz,.blocked
        ld a,b
        cp 105
        jr c,.exit_left
        cp 177
        jr c,.blocked
        ld a,l                  ; right margin: previous centre < new centre
        cp b
        ret c
        jr .blocked
.exit_left:
        ld a,b                  ; left margin: new centre < previous centre
        cp l
        ret c
.blocked:
        ld hl,(0xc8d6)
        ld (0xc800),hl          ; block horizontal passage through the boxes
        ret
.outside:
        ld a,(0xc804)
        or a
        ret nz
        xor a
        ld (0xc8d4),a
        ret

; Single box after the first stack, approximately world x=674..708. Its top
; is 28px above the industrial floor, based on the captured background.
.second_crate:
        ld a,l
        ld b,a
        ld a,(0xc8d4)
        cp 2
        jr nz,.second_not_on_top
        ld a,(0xc804)
        or a
        ret nz
        ld a,b
        cp 162
        jr c,.second_leave
        cp 197
        ret c
.second_leave:
        xor a
        ld (0xc8d4),a
        ret
.second_not_on_top:
        ld a,b
        cp 162
        jr c,.second_side
        cp 197
        jr nc,.second_side
        ld a,(0xc804)
        or a
        jr z,.second_side
        cp 20
        jr nc,.second_side
        ld a,(0xc80a)
        cp 29
        jr nc,.second_side
        ld a,2
        ld (0xc8d4),a
        xor a
        ld (0xc804),a
        ld (0xc808),a
        ret
.second_side:
        ld a,b
        cp 150
        ret c
        cp 209
        ret nc
        ld a,(0xc80a)
        cp 28
        ret nc
        ld a,(0xc8d7)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld de,32
        add hl,de
        ld a,h
        cp 3
        jr nz,.second_blocked
        ld a,b
        cp 162
        jr c,.second_exit_left
        cp 197
        jr c,.second_blocked
        ld a,l
        cp b
        ret c
        jr .second_blocked
.second_exit_left:
        ld a,b
        cp l
        ret c
.second_blocked:
        ld hl,(0xc8d6)
        ld (0xc800),hl
        ret


; Brown crate and tall green container at world x≈385..443. They are too
; tall to cross with a ground jump. The hanging path skips this routine.
; A player dropped inside can still leave on either side.
.third_crates:
        ld a,l
        cp 112                 ; left collision edge: 368
        ret c
        cp 200                 ; right collision edge: 456
        ret nc
        ld b,a
        ld a,(0xc8d7)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld de,32
        add hl,de
        ld a,h
        cp 2
        jr nz,.third_block
        ld a,l
        cp 112
        jr c,.third_block
        cp 200
        jr nc,.third_block
        ; Already inside: allow only movement towards the nearest exit.
        cp 156                 ; middle of the obstacle
        jr nc,.third_inside_right
        ld a,b
        cp l
        ret c
        jr .third_block
.third_inside_right:
        ld a,l
        cp b
        ret c
.third_block:
        ld hl,(0xc8d6)
        ld (0xc800),hl
        ret
