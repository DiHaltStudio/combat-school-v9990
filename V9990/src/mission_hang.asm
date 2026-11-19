; Hanging from the industrial pipes. c8dd is the hanging state. The player
; catches the low pipe when jumping from ground or the second box. M releases.
mission_hang_update:
        ld a,(0xc8dd)
        or a
        jr nz,.hanging
        ; Catch only under the low pipe, not in the adjoining rooms or in
        ; the section whose artwork has no reachable lower pipe.
        ld hl,(0xc840)
        ld a,(0xc801)
        ld e,a
        ld d,0
        add hl,de
        ld de,32
        add hl,de
        ld de,631
        or a
        sbc hl,de
        ret c
        ld de,350               ; catch interval: world centre 631..980
        or a
        sbc hl,de
        ret nc
        ld a,(0xc8d4)
        cp 2
        jr z,.crate_jump
        or a
        ret nz                  ; other raised platforms use different heights
        ld a,(0xc804)
        cp 22                   ; near the top of a ground jump
        ret nc
        cp 13                   ; release starts at 12, preventing re-grabbing
        ret c
        jr .catch
.crate_jump:
        ld a,(0xc804)
        cp 25
        ret nc
        cp 18
        ret c
.catch:
        ld a,1
        ld (0xc8dd),a
        xor a
        ld (0xc804),a
        ld (0xc808),a
        ld (0xc803),a
        ld (0xc8d4),a
        ld (0xc8de),a
        ld (0xc8df),a
        ret
.hanging:
        ld a,(0xc823)
        or a
        jp nz,.drop
        ; M is read directly, with the same keyboard/joystick mapping as jump.
        ld a,4
        call in_snsmat
        bit 2,a
        ld a,0xff
        jr z,.button
        ld a,2
        call in_trig
.button:
        ld b,a
        ld a,(0xc806)
        ld c,a
        ld a,b
        ld (0xc806),a
        or a
        jr z,.direction
        ld a,c
        or a
        jp z,.drop
.direction:
        xor a
        call in_stick
        or a
        jr nz,.have_direction
        ld a,1
        call in_stick
.have_direction:
        cp 6
        jr z,.left
        cp 7
        jr z,.left
        cp 8
        jr z,.left
        cp 2
        jr z,.right
        cp 3
        jr z,.right
        cp 4
        ret nz
.right:
        xor a
        ld (0xc809),a
        ld de,0x0100
        jr .move
.left:
        ld a,1
        ld (0xc809),a
        ld de,0xff00
.move:
        ld hl,(0xc800)
        add hl,de
        ld a,h
        cp 24
        ret c
        cp 170
        ret nc
        ; Check the candidate world centre before changing player or camera.
        ; The lower industrial pipe ends at the doorway, not in the brick room.
        push hl
        ld e,h
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld de,32-550           ; centre cannot pass the left pipe end
        add hl,de
        jr nc,.end_blocked
        ld de,575              ; inclusive right limit: centre 1124
        or a
        sbc hl,de
        jr nc,.end_blocked
        pop hl
        ld (0xc800),hl
        ; Advance the hand-over-hand cycle only when movement succeeds.
        ld hl,0xc8df
        inc (hl)
        ld a,(hl)
        and 8
        ld (0xc8de),a
        ret
.end_blocked:
        pop hl
        ret
.drop:
        xor a
        ld (0xc8dd),a
        ld (0xc8d4),a
        ld (0xc808),a
        ld a,12                 ; start in the descending half of the jump
        ld (0xc804),a
        ret

mission_hang_draw:
        ld a,(0xc8dd)
        or a
        ret z
        ld a,(0xc8de)
        add a,a
        add a,a
        add a,a                 ; alternating 64-pixel frames
        ld b,a
        ld a,(0xc809)
        or a
        ld a,b
        jr nz,.source
        add a,128
.source:
        ; Copy only the opaque bounds shared by all four hanging poses.
        add a,20
        ld (0xc300),a
        xor a
        ld (0xc301),a
        ld a,6
        ld (0xc302),a
        ld a,2                  ; source y=512
        ld (0xc303),a
        ld a,(0xc801)
        add a,20
        ld (0xc304),a
        xor a
        ld (0xc305),a
        ld a,87                 ; preserve hands: original destination 81 + crop 6
        ld (0xc306),a
        ld a,24
        ld (0xc308),a
        ld a,71
        ld (0xc30a),a
        ret
