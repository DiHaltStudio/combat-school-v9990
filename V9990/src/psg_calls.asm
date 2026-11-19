; Music calls for any part of the game (src/psg_music.asm). They do nothing
; unless the driver is installed: the standalone test ROMs of each step
; have no music. Every register and flag is kept. The addresses are fixed
; here so that each part needs no generated file; tools/build_psg_music.py
; checks them.
;   psg_play with A = song (0-9); psg_stop to silence; psg_sfx with A =
;   effect (SFX_*), psg_countdown with A = seconds left. Both end the hats
;   of the graduation (src/psg_hats.asm) if they still play, and the
;   deferred ticks (psg_defer_on).
PSG_CALL_START equ 0xe0e5
PSG_CALL_SFX equ 0xe13e         ; effect A (0-19), over the song
PSG_CALL_STOP equ 0xe194
PSG_CALL_HOOK equ 0xdf          ; high byte of the H.TIMI hook
PSG_CALL_STREAM equ 0xdf00      ; psg_stream of src/psg_music.asm
PSG_CALL_DEFER equ 0xdf03       ; psg_defer, then psg_pending
PSG_CALL_TICK equ 0xe000
PSG_CALL_SONG_ON equ 0xe002     ; non-zero while a song plays
PSG_CALL_ARC_ON equ 0xd130      ; ARC_ON of src/psg_arcade.asm
PSG_CALL_ARC_LOAD equ 0xd148    ; arc_load
; Arcade songs arranged for the PSG (psg_arcade, A =):
ARC_MANSION equ 0               ; the mansion when the mission ends (arcade 2Eh)
ARC_TITLE equ 1                 ; YOUR TITLE (38h)
ARC_RANKING equ 2               ; the RANKING table (24h)
ARC_GAME_OVER equ 3             ; GAME OVER (2Ah)
ARC_SERGEANT equ 4              ; the sergeant before the penalty (22h)
ARC_CHIN_UPS equ 5              ; the chin-ups (2Bh)
ARC_CADETS equ 6                ; the cadets running after the Iron-Man bonus (27h)
ARC_WICKED_CHILD equ 7         ; alternate MSX flag (user-selected)
; Effects of the Spectrum driver, where the Spectrum game uses them
; (../musicPsg/README.md, «Efectos»):
SFX_SHOT equ 2                  ; tanks gallery: each shot
SFX_HIT equ 3                   ; both galleries: a target hit
SFX_POINTS equ 4                ; tanks gallery: a hit that scores
SFX_WARNING equ 9               ; each of the last 6 seconds
SFX_TIME_UP equ 10              ; the clock reaches zero
SFX_BLOW equ 13                 ; fight: a blow lands
psg_play:
        push af
        call psg_check
        jr nz,psg_none
        pop af
        push af
        call PSG_CALL_START     ; keeps BC, DE, HL, IX
        jr psg_none
; A = arcade song (ARC_*): it plays instead of the driver. It maps the
; songs' bank at page 2 and leaves it there: the caller maps back what it
; needs. Enables interrupts. Keeps BC, DE, HL.
psg_arcade:
        push af
        call psg_check
        jr nz,psg_none
        pop af
        push af
        push bc
        push de
        push hl
        call PSG_CALL_ARC_LOAD
        pop hl
        pop de
        pop bc
        jr psg_none
; A = effect (SFX_*): the driver plays it over the song, as the Spectrum.
; Nothing while an arcade song plays (the driver does not tick then).
; Keeps every register and flag.
psg_sfx:
        push af
        ld a,(0xfda1)
        cp PSG_CALL_HOOK
        jr nz,psg_none
        ld a,(PSG_CALL_ARC_ON)
        or a
        jr nz,psg_none
        pop af
        push af
        call PSG_CALL_SFX       ; keeps BC, DE, HL
        jr psg_none
; A = seconds left, after the clock went down one: as the Spectrum
; (9106h), a warning in each of the last 6 seconds, and at zero the time
; up. Keeps every register and flag.
psg_countdown:
        push af
        push bc
        ld b,SFX_TIME_UP
        or a
        jr z,.play
        cp 7
        jr nc,.none
        ld b,SFX_WARNING
.play:
        ld a,b
        call psg_sfx
.none:
        pop bc
        pop af
        ret
psg_stop:
        push af
        call psg_check
        call z,PSG_CALL_STOP    ; changes only A
        ld a,8                  ; volumes 0: an arcade song's last notes too
.mute:
        out (0xa0),a
        push af
        xor a
        out (0xa1),a
        pop af
        inc a
        cp 11
        jr nz,.mute
psg_none:
        pop af
        ret
; Z when the music is installed; then the hats are ended.
psg_check:
        ld a,(0xfda1)           ; H.TIMI jumps to the music hook?
        cp PSG_CALL_HOOK
        ret nz
        push hl
        ld hl,0
        ld (PSG_CALL_STREAM),hl ; one instruction: the interrupt sees 0 or not
        ld (PSG_CALL_DEFER),hl  ; ticks from the interrupt again, none pending
        ld (PSG_CALL_ARC_ON),hl ; no arcade song (src/psg_arcade.asm)
        pop hl
        cp a                    ; Z
        ret

; Waits (with interrupts on) until the song ends, at most about 10 s, so a
; bonus screen stays until its music is over. Keeps every register.
psg_wait_song:
        push af
        push bc
        ld a,(0xfda1)
        cp PSG_CALL_HOOK
        jr nz,.over             ; no music installed
        ld bc,3*256             ; up to 768 interrupts
.wait:
        ld a,(PSG_CALL_SONG_ON)
        or a
        jr z,.over
        ei
        halt
        dec bc
        ld a,b
        or c
        jr nz,.wait
.over:
        pop bc
        pop af
        ret

; The final mission: the interrupt only counts the ticks (the mission, with
; interrupts off, plays them itself: src/mission_boss.asm mission_frame_tick).
psg_defer_on:
        push af
        call psg_check
        jr nz,psg_none
        ld a,1
        ld (PSG_CALL_DEFER),a
        jr psg_none

; Screen changes (18-nov). Turning the display off in the middle of a frame
; can cut that frame (the top of the old picture over black), and a palette
; or picture written while it still shows flashes. display_off writes R8
; inside the vertical retrace (P#5 bit 6), between two frames, with the
; interrupts held off for those few instructions, then waits until the
; retrace ends: the whole next frame is off, whether the V9990 takes R8 at
; once or when the frame starts. At most two frames. wait_retrace waits for
; the retrace to begin: a palette written then (48 bytes take a few lines)
; changes between two frames, never in the middle of one. Both keep the
; interrupts as they are and every register but A and F.
display_off:
        ld a,i                  ; P/V = interrupts enabled
        push af
        di
        call wait_retrace
        ld a,8
        out (0x64),a
        ld a,0x42               ; display off, sprites off, 512 KiB VRAM
        out (0x63),a
        pop af
        jp po,.started
        ei
.started:
        in a,(0x65)
        bit 6,a
        jr nz,.started
        ret
wait_retrace:
        in a,(0x65)
        bit 6,a
        jr nz,wait_retrace
.retrace:
        in a,(0x65)
        bit 6,a
        jr z,.retrace
        ret
