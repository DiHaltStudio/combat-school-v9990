; One-shot first-room reinforcement cues. Camera thresholds are approximate
; placements derived from the recorded route, not recovered arcade tables.
; c8ad = next cue, c8ae = minimum interval between reinforcements.
mission_waves_tick:
        ld a,(0xc856)
        or a
        ret z
        ld hl,0xc8ae
        ld a,(hl)
        or a
        jr z,.ready
        dec (hl)
        ret
.ready:
        ; Past the first crate, encounters are placed explicitly in the
        ; industrial section; do not create generic extra reinforcements.
        ld hl,(0xc840)
        ld de,1026
        or a
        sbc hl,de
        ret c
        ld a,(0xc8ad)
        cp 8
        ret nc
.select_cue:
        cp 11
        ret nc
        ld e,a
        ld d,0
        ld hl,mission_wave_thresholds
        add hl,de
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,(0xc840)
        or a
        sbc hl,de
        ret nc                  ; camera must pass the next cue
        ld a,(0xc8ad)
        and 1
        jr nz,.right_first
        call .left
        jr c,.spawned
        call .right
        ret nc
        jr .spawned
.right_first:
        call .right
        jr c,.spawned
        call .left
        ret nc
.spawned:
        ld hl,0xc8ad
        inc (hl)
        ld a,55
        ld (0xc8ae),a
        ret
.left:
        ld a,(0xc851)
        cp 5
        jr nz,.unavailable
        ld a,(0xc801)
        cp 64
        jr c,.unavailable       ; don't appear close to the player
        xor a
        ld (0xc850),a
        ld (0xc851),a
        ld (0xc855),a
        ld (0xc858),a
        ld (0xc8f5),a
        ld a,(0xc8e0)
        or a
        jr z,.left_ready
        ld a,1
        ld (0xc8f5),a          ; blue knife thrower at the later doorway
.left_ready:
        scf
        ret
.right:
        ld a,(0xc871)
        cp 5
        jr nz,.unavailable
        ld a,(0xc801)
        cp 129
        jr nc,.unavailable
        xor a
        ld (0xc870),a
        ld (0xc871),a
        ld (0xc875),a
        ld (0xc878),a
        ld (0xc8f4),a
        ld a,(0xc8e0)
        or a
        jr z,.right_ready
        ; Orange assailant approaches from the right in the recorded scene.
        ld a,1
        ld (0xc8f4),a
.right_ready:
        scf
        ret
.unavailable:
        or a                    ; clear carry
        ret

; Threshold + 1, so equality triggers. At most eight additional blues.
mission_wave_thresholds:
        dw 1545,1481,1417,1353,1289,1225,1161,1097
        dw 0                   ; index 8 is the first-room sentinel
        dw 836,756             ; observed orange from right, blue from left
