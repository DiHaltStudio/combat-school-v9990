; Arcade songs arranged for the PSG (tools/build_psg_arcade.py, from
; ../musicPsg/tools/arreglo_arcade.py): the mansion at the end of the
; mission, YOUR TITLE, the RANKING, GAME OVER, the penalty's sergeant and
; chin-ups and the cadets after the Iron-Man, which the Spectrum version has not. Lists of notes with lengths;
; this player gives each note the envelope of the Spectrum's song 0 and a
; short release. Needs build/psg/arcade.inc and build/psg/driver.inc.
;
; In RAM from ARC_RAM (D130h), copied by psg_install (src/psg_music.asm):
; the state, then the code and its tables; the song being played is copied
; to ARC_BUF (D400h-DBFFh). D130h-DBFFh are free in every part of the game.
; arc_load (A = song) is called through psg_arcade (src/psg_calls.asm); it
; maps the songs' bank at page 2 and leaves it there. The H.TIMI hook calls
; arc_tick at 50 Hz instead of the driver while ARC_ON is set; psg_play and
; psg_stop clear it.

ARC_RAM equ 0xd130
ARC_BUF equ 0xd400
ARC_BUF_END equ 0xdc00
        assert ARC_BUF+ARC_BIGGEST <= ARC_BUF_END

arc_ram:
        phase ARC_RAM
ARC_ON:
        db 0                    ; not 0: an arcade song plays
arc_wait:
        db 0                    ; ticks until the next note
arc_ptr:
        dw 0
arc_loop:
        dw 0
arc_ch:
        ds 12                   ; per channel: (unused) 2, age, key-on length
        ds 0xd148-$
        assert $ == 0xd148      ; PSG_CALL_ARC_LOAD of src/psg_calls.asm

; A = song: the songs' bank at page 2 (left there), the song to ARC_BUF,
; then it plays from the next tick. Returns with interrupts enabled.
arc_load:
        di
        push af
        call PSG_STOP           ; the driver silent
        xor a
        ld (ARC_ON),a
        ld h,a
        ld l,a
        ld (PSG_HOOK),hl        ; psg_stream: the hats end
        ld a,ARC_BANK
        ld (0x7000),a
        pop af
        add a,a
        add a,a
        ld l,a
        ld h,0x80
        inc hl                  ; directory at 8001h: offset, length
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ex de,hl
        ld de,ARC_BUF
        ldir
        ld hl,ARC_BUF
        ld (arc_ptr),hl
        ld (arc_loop),hl
        xor a
        ld (arc_wait),a
        ld hl,arc_ch
        ld b,12
.clear:
        ld (hl),a
        inc hl
        djnz .clear
        ld a,7
        out (0xa0),a
        ld a,0xb8               ; tones on, noise off, port B out, port A in
        out (0xa1),a
        ld a,1
        ld (ARC_ON),a
        ei
        ret

; Once per 50 Hz tick (the H.TIMI hook): the notes due, then the volumes.
arc_tick:
        ld hl,arc_wait
        ld a,(hl)
        or a
        jr z,.notes
        dec (hl)
        jr nz,.voices
.notes:
        ld hl,(arc_ptr)
.note:
        ld a,(hl)               ; channel and note
        inc hl
        ld e,(hl)               ; key-on length
        inc hl
        push hl
        call arc_start
        pop hl
.delta:
        ld a,(hl)
        inc hl
        cp 250
        jr c,.wait
        cp 254
        jr z,.mark
        cp 253
        jr z,.jump
        xor a                   ; 255: the end, silent
        ld (ARC_ON),a
        ld bc,3*256+8
.mute:
        ld a,c
        out (0xa0),a
        xor a
        out (0xa1),a
        inc c
        djnz .mute
        ret
.mark:
        ld (arc_loop),hl
        jr .delta
.jump:
        ld hl,(arc_loop)
        jr .delta
.wait:
        or a
        jr z,.note
        ld (arc_wait),a
        ld (arc_ptr),hl
.voices:
        ld hl,arc_ch+2          ; channel A: age, length
        ld c,8                  ; its volume register
.voice:
        inc hl
        ld b,(hl)               ; key-on length (0: idle)
        dec hl
        ld a,b
        or a
        jr z,.silent
        ld a,(hl)               ; age
        cp b
        jr nc,.released
        cp ARC_ENV_LEN
        ld d,ARC_SUSTAIN
        jr nc,.level
        call arc_envelope_at
        ld d,a
        jr .level
.released:
        sub b                   ; ticks since the key off
        cp ARC_REL_LEN
        jr nc,.over
        push hl
        ld e,a
        ld d,0
        ld hl,arc_release
        add hl,de
        ld e,(hl)               ; the release's level
        pop hl
        ld a,b
        dec a
        cp ARC_ENV_LEN
        ld a,ARC_SUSTAIN
        jr nc,.min
        ld a,b
        dec a
        call arc_envelope_at    ; the level at the key off
.min:
        cp e
        jr c,.min_ready
        ld a,e
.min_ready:
        ld d,a
        jr .level
.over:
        inc hl
        ld (hl),0               ; idle
        dec hl
.silent:
        ld d,0
        jr .out
.level:
        ld a,(hl)
        inc a
        jr z,.out               ; age stays at 255
        ld (hl),a
.out:
        ld a,c
        out (0xa0),a
        ld a,d
        out (0xa1),a
        ld de,4
        add hl,de
        inc c
        ld a,c
        cp 11
        jr c,.voice
        ret

; A = tick of the key on: A = its envelope level (A < ARC_ENV_LEN). Keeps
; BC, DE, HL.
arc_envelope_at:
        push hl
        push de
        ld e,a
        ld d,0
        ld hl,arc_envelope
        add hl,de
        ld a,(hl)
        pop de
        pop hl
        ret

; A = channel (bits 7-6; 3: none) and note - 24, E = key-on length: the
; tone period written, the channel's envelope restarted.
arc_start:
        ld b,e
        ld d,a
        and 0xc0
        cp 0xc0
        ret z
        rlca
        rlca
        ld c,a                  ; channel 0-2
        ld a,d
        and 63
        add a,a
        ld l,a
        ld h,0
        ld de,arc_periods
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,c
        add a,a
        out (0xa0),a
        ld a,e
        out (0xa1),a
        ld a,c
        add a,a
        inc a
        out (0xa0),a
        ld a,d
        out (0xa1),a
        ld a,c
        add a,a
        add a,a
        add a,2
        ld l,a
        ld h,0
        ld de,arc_ch
        add hl,de
        ld (hl),0               ; age
        inc hl
        ld (hl),b               ; key-on length
        ret

        include "../build/psg/arcade.inc"
        assert $ <= ARC_BUF
        dephase
arc_ram_end:
ARC_RAM_SIZE equ arc_ram_end-arc_ram
