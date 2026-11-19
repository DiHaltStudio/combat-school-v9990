; PSG music: the Spectrum 128K driver of Combat School (tools/build_psg_music.py)
; copied to RAM at PSG_BASE (E000h-EEFFh: free in the game, and a move by a
; multiple of 1000h, as some notes read their period high byte past the
; period table, from the order lists, and the PSG only keeps its low
; nibble), ticked from the H.TIMI hook at PSG_HOOK (DF00h) on the MSX VDP
; interrupt. EF00h-EFFFh stay for the stack (it starts at F000h).
; The driver runs at 50 Hz, as on the Spectrum: on a 60 Hz MSX one
; interrupt in six is skipped, so the tempo is the same.
; The hats in the air of the graduation (hats.bin at PSG_HATS, DC00h) are
; register writes: while psg_stream is not 0 the hook plays them instead of
; the driver, then starts song 0 (src/psg_calls.asm psg_hats).
; Needs build/psg/driver.inc (PSG_*).
;
; psg_install: HL = build/psg/driver.bin in memory, with hats.bin 400h
;   bytes before it (in the game, bank PSG_ROM_BANK mapped at 8000h).
;   Copies them and the hook to RAM, silences the driver and hooks H.TIMI,
;   keeping the previous hook, which runs after the music. Returns with
;   interrupts enabled. Once installed (each new game passes through it
;   again) it only silences the music.
; Then: A = song, call PSG_START; call PSG_STOP; (PSG_SONG_ON) non-zero
; while a song plays. Arcade songs arranged for the PSG: src/psg_arcade.asm,
; also copied to RAM here, played by the hook while ARC_ON is set.
; Deferred ticks (the final mission, whose frames have under 1 ms spare): with
; psg_defer set the hook only counts the 50 Hz ticks; the mission runs with
; interrupts off and plays them after drawing each frame when it has room
; (src/mission_boss.asm mission_frame_tick); psg_play and psg_stop end that
; mode.

H_TIMI equ 0xfd9f
PSG_HOOK equ PSG_BASE-0x100

psg_ram:
        phase PSG_HOOK
psg_stream:
        dw 0                    ; next event of hats.bin (0: the driver plays)
psg_wait:
        db 0                    ; ticks left until that event
psg_defer:
        db 0                    ; not 0: the hook only counts the ticks (mission)
psg_pending:
        db 0                    ; ticks counted (the mission plays its own, src/mission_boss.asm)
psg_hook:
        push af                 ; A = VDP status, for the next hook
        ld a,(0x002b)           ; BIOS: bit 7 set on a 50 Hz MSX
        rla
        jr c,.tick
        ld hl,psg_skip
        dec (hl)
        jr nz,.tick
        ld (hl),6
        jr .done
.tick:
        ld a,(psg_defer)
        or a
        jr z,.now
        ld hl,psg_pending
        inc (hl)
        jr .done
.now:
        ld a,(ARC_ON)           ; an arcade song (src/psg_arcade.asm)
        or a
        jr z,.driver
        call arc_tick
        jr .done
.driver:
        ld hl,(psg_stream)
        ld a,h
        or l
        jr nz,.stream
        call PSG_TICK
        jr .done
.stream:
        ld a,(psg_wait)
        dec a
        ld (psg_wait),a
        jr nz,.done
        ld b,(hl)               ; register writes of this event
        inc hl
        inc b
        dec b
        jr z,.end
.write:
        ld a,(hl)
        out (0xa0),a
        inc hl
        ld a,(hl)
        out (0xa1),a
        inc hl
        djnz .write
        ld a,(hl)               ; ticks until the next event
        inc hl
        ld (psg_wait),a
        ld (psg_stream),hl
        jr .done
.end:
        ld h,b
        ld l,b
        ld (psg_stream),hl
        xor a                   ; then the graduation, from this tick
        call PSG_START
        call PSG_TICK
.done:
        pop af
psg_old:
        ds 5                    ; the previous H.TIMI (RET, or an inter-slot call)
psg_skip:
        db 6
psg_ram_end:
        dephase
PSG_HOOK_SIZE equ psg_ram_end-psg_stream
        assert psg_defer == PSG_HOOK+3 && psg_pending == PSG_HOOK+4   ; src/psg_calls.asm

        include "psg_arcade.asm"

psg_install:
        di
        ld a,(H_TIMI+2)
        cp PSG_HOOK>>8
        jr nz,.install
        ld a,(H_TIMI)
        cp 0xc3
        jr nz,.install
        ld hl,0                 ; already hooked (a new game): silence only
        ld (psg_stream),hl
        call PSG_STOP
        ei
        ret
.install:
        push hl
        ld bc,-0x400
        add hl,bc
        ld de,PSG_HATS
        ld bc,PSG_HATS_SIZE
        ldir
        pop hl
        ld de,PSG_BASE
        ld bc,PSG_SIZE
        ldir
        ld hl,psg_ram
        ld de,PSG_HOOK
        ld bc,PSG_HOOK_SIZE
        ldir
        ld hl,arc_ram           ; the arcade songs' player (src/psg_arcade.asm)
        ld de,ARC_RAM
        ld bc,ARC_RAM_SIZE
        ldir
        call PSG_STOP           ; the dump says a song plays (C002h = FFh)
        ld hl,H_TIMI
        ld de,psg_old
        ld bc,5
        ldir
        ld hl,psg_hook
        ld (H_TIMI+1),hl
        ld a,0xc3               ; JP psg_hook
        ld (H_TIMI),a
        ei
        ret
