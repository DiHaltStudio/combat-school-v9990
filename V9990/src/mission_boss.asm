; Final guardian. Arcade fixed ROM B8B2..BAEC: 8 health, +/-0060
; walking, two attack sequences, phase-2 contact, blocks and recoil.
; This is a frame-based adaptation, not a translation of the HD6309 AI.
; C980 record mirrors the chain record; +6 health, +7 recovery,
; +9 attack kind, +14 block phase. The president remains a static actor.
mission_boss_tick:
        ld a,(0xc981)
        or a
        jr nz,.active
        ld hl,(0xc840)
        ld de,109
        or a
        sbc hl,de
        ret nz
        ld a,1
        ld (0xc981),a
        ld hl,141
        ld (0xc982),hl
        ld a,8
        ld (0xc986),a
        xor a
        ld (0xc984),a
        ld (0xc985),a
        ld (0xc987),a
        ld (0xc988),a
        ld (0xc989),a
        ld (0xc98a),a
        ld (0xc98b),a
        ld (0xc98c),a
        ld (0xc98e),a
        ld (0xc98f),a
        ; Replace the static guardian on both pages without leaving ghosts.
        ld (0xca26),a
        ld (0xca27),a
        dec a
        ld (0xc9e0),a
        ld (0xc9e1),a
        ret
.active:
        cp 5
        jp z,mission_boss_fallen
        ld a,(0xc856)
        or a
        ret z
        ld hl,0xc987
        ld a,(hl)
        or a
        jr z,.cooldown
        dec (hl)
.cooldown:
        ld a,(0xc803)
        or a
        jr nz,.latch
        ld (0xc98a),a
.latch:
        ld a,(0xc981)
        cp 3
        jp nc,.reaction
        ld a,(0xc801)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld (0xc9b4),hl
        ld de,(0xc982)
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
        ld (0xc9b6),a
        ld (0xc9b2),hl
        ld a,(0xc981)
        cp 2
        jr z,.hit_check
        ld a,(0xc9b6)
        ld (0xc988),a
.hit_check:
        ld a,h
        or a
        jp nz,.behaviour
        ld a,l
        cp 30
        jp nc,.behaviour
        ld a,(0xc987)
        or a
        jp nz,.behaviour
        ld a,(0xc98a)
        or a
        jp nz,.behaviour
        ld a,(0xc823)
        or a
        jp nz,.behaviour
        ld a,(0xc8dd)
        or a
        jp nz,.behaviour
        ld a,(0xc80a)
        cp 40
        jp nc,.behaviour
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
        jr z,.contact
        ld a,(0xc803)
        cp 19
        jp c,.behaviour
.contact:
        ld a,1
        ld (0xc98a),a
        ; Deterministic stand-in for B9A9's difficulty/health phase mask.
        ; Every third grounded contact is blocked; aerial kicks evade it.
        ld hl,0xc98e
        inc (hl)
        ld a,(0xc804)
        or a
        jr nz,.damage
        ld a,(hl)
        cp 3
        jr c,.damage
        ld (hl),0
        ld a,6
        ld (0xc981),a
        ld a,12
        ld (0xc984),a
        ld a,7
        ld (0xc98f),a
        ret
.damage:
        ld hl,0xc986
        dec (hl)
        ld a,3
        ld b,24
        jr nz,.hurt
        ld a,4
        ld b,52
.hurt:
        ld (0xc981),a
        ld a,b
        ld (0xc984),a
        ld a,36
        ld (0xc987),a
        ld a,8
        ld (0xc98f),a
        ld hl,(0xc982)
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
.behaviour:
        ld a,(0xc981)
        cp 2
        jp z,.attack
        ld hl,(0xc9b2)
        ld a,h
        or a
        jr nz,.walk
        ld a,l
        cp 31
        jr nc,.walk
        ld a,2
        ld (0xc981),a
        ld a,(0xc989)
        xor 1
        ld (0xc989),a
        ld a,40
        jr z,.attack_timer
        ld a,16
.attack_timer:
        ld (0xc984),a
        ld a,4
        ld (0xc98f),a
        ret
.walk:
        ld hl,0xc985
        inc (hl)
        ld a,(hl)
        and 24
        rrca
        rrca
        rrca
        cp 3
        jr c,.walk_pose
        xor a
.walk_pose:
        inc a
        ld (0xc98f),a
        ld a,(0xc98c)
        add a,96                 ; exact 8.8 magnitude from B92C/B937
        ld (0xc98c),a
        ret nc
        ld hl,(0xc982)
        ld a,(0xc988)
        or a
        jr nz,.left
        inc hl
        jp .save
.left:
        dec hl
.save:
        ld a,h
        or a
        jr nz,.save_world
        ld a,l
        cp 141                  ; arcade minimum x=$40, rebased to this map
        jr nc,.save_world
        ld hl,141
.save_world:
        ld (0xc982),hl
        ret
.attack:
        ld hl,0xc984
        dec (hl)
        jp z,.ready
        ld a,(0xc989)
        or a
        ld a,(hl)
        jr nz,.punch
        cp 25
        ret nc
        cp 17
        jr c,.recover
        ld a,6                ; long punch sequence $5693
        jr .strike
.punch:
        cp 9
        ret nc
        cp 5
        jr c,.recover
        ld a,5                ; short kick sequence $56a3
.strike:
        ld (0xc98f),a
        ld a,(0xc9b6)
        ld b,a
        ld a,(0xc988)
        cp b
        ret nz
        ld hl,(0xc9b2)
        ld a,h
        or a
        ret nz
        ld a,l
        cp 34
        ret nc
        ld a,(0xc80a)
        cp 28
        ret nc
        ld a,(0xc8dd)
        or a
        ret nz
        ld a,(0xc857)
        or a
        ret nz
        ld hl,0xc856
        dec (hl)
        jp z,mission_player_hit
        ld a,36
        ld (0xc857),a
        ld a,18
        ld (0xc823),a
        xor a
        ld (0xc803),a
        ld hl,(0xc9b4)
        ld a,112
        call mission_start_impact
        ld a,(0xc988)
        or a
        ld a,(0xc801)
        jr nz,.player_left
        add a,12
        cp 185
        jr c,.player_save
        ld a,184
        jr .player_save
.player_left:
        sub 12
        cp 24
        jr nc,.player_save
        ld a,24
.player_save:
        ld (0xc801),a
        ret
.recover:
        xor a
        ld (0xc98f),a
        ret
.reaction:
        ld hl,0xc984
        dec (hl)
        jr z,.reaction_done
        ld a,(0xc981)
        cp 6
        ret z
        cp 4
        jr nz,.recoil
        ld a,(hl)
        cp 36
        ret nc
        ld a,9
        ld (0xc98f),a
        ret
.recoil:
        ld a,(hl)
        cp 16
        ret c
        ld hl,(0xc982)
        ld a,(0xc988)
        or a
        ld de,2
        jr nz,.recoil_move
        ld de,65534
.recoil_move:
        add hl,de
        ld a,h
        or a
        jr nz,.recoil_clamp
        ld a,l
        cp 141
        jp nc,.save
.recoil_clamp:
        ld hl,141
        jp .save
.reaction_done:
        ld a,(0xc981)
        cp 4
        jr nz,.ready
        ld a,5
        ld (0xc981),a
        ld a,10
        ld (0xc98f),a
        ; Arcade: 100000 points, then the ending (src/mission_ending.asm).
        ld hl,(0xc75c)
        ld de,0x86a0
        add hl,de
        ld (0xc75c),hl
        ld a,(0xc75e)
        adc a,1
        ld (0xc75e),a
        ld hl,MISSION_ENDING_DELAY
        ld (MISSION_ENDING_TIMER),hl
        ret                       ; defeated guardian remains on the floor
.ready:
        ld a,1
        ld (0xc981),a
        xor a
        ld (0xc98f),a
        ret
; Defeated: the game goes on (the player walks) until the ending.
mission_boss_fallen:
        ld hl,(MISSION_ENDING_TIMER)
        dec hl
        ld (MISSION_ENDING_TIMER),hl
        ld a,h
        or l
        ret nz
; The arcade ending: the mansion in daylight (its tables in the ending bank
; at page 2), then that bank at page 1 for the texts and the RANKING table
; (src/ranking.asm, 0x4013).
mission_ending:
        di
        ld sp,0xf000
        ld a,ENDING_BANK
        ld (0x7000),a
        ld (PRE_HOME),a
        ld hl,0
        ld (PRE_HOOK),hl
        ld a,13
        out (0x64),a
        ld hl,settings
        ld bc,0x0863
        otir                    ; R13..R20: palette and scroll as at start
        ld a,ARC_MANSION        ; victory: the mansion music of the arcade (2Eh),
        call psg_arcade         ; which also enables interrupts again (the
                                ; mission ran with them off)
        ld a,ENDING_BANK
        ld (0x7000),a           ; psg_arcade left the songs' bank at page 2
        ld hl,prelude_ending
        call prelude_screen     ; ends with the display off
        ld hl,mission_ranking_jump
        ld de,0xf2a0
        ld bc,mission_ranking_jump_end-mission_ranking_jump
        ldir
        jp 0xf2a0
mission_ranking_jump:
        ld a,ENDING_BANK
        ld (0x6000),a
        jp 0x4013
mission_ranking_jump_end:
MISSION_ENDING_TIMER equ 0xd0b8
MISSION_ENDING_DELAY equ 270    ; arcade frames from the fall to the fade
mission_boss_draw:
        ld a,(0xc981)
        or a
        ret z
        ld hl,(0xc982)
        ld (0xc9ba),hl
        ld a,(0xc98f)
        add a,a
        ld b,a
        ld a,(0xc988)
        add a,b
        ld de,mission_boss_poses
        jp mission_pose_draw

; Left damage cells: precomposed strips at y=2448. One copy per change/page.
mission_boss_hud:
        ld a,(0xc981)
        or a
        ret z
        ld a,(0xc802)
        ld e,a
        ld d,0
        ld hl,0xc9e0
        add hl,de
        ld a,(0xc986)
        cp (hl)
        ret z
        ld (hl),a
        ld b,a
        ld a,8
        sub b
        add a,a
        add a,a
        add a,a
        add a,144
        push af
        ld hl,mission_hud_template
        call copy_command
        pop af
        ld (0xc302),a
        ld a,24
        ld (0xc306),a
        xor a
        ld (0xc309),a
        ld a,112
        ld (0xc308),a
        ld a,8
        ld (0xc30a),a
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        jp command

; The mission runs with interrupts disabled (tools/build_mission_visual.py):
; once per V9990 frame (60 Hz), after drawing, JIFFY goes on and five frames
; in six owe a music tick (50 Hz). A tick (about 1.1 ms, up to 2.3) is
; played only when the frame has room for it: the wait for the next frame
; counts its turns (37 T, about 97 per ms) into MISSION_SPARE; the spare time
; this frame would have without a tick is that count, plus the ticks the
; last frame played. Otherwise the tick waits (at most 6), so the few heavy
; frames are not lost; frames with room then play two ticks to catch up.
; After a lost frame the wait counted a whole extra frame: no tick then.
; RAM: DF04 (the hook's pending count, unused with interrupts off) the
; six-frame cycle; D0F0 ticks owed, D0F1 last frame ticked, D0F2 spare.
MISSION_TICKS equ 0xd0f0
MISSION_TICKED equ 0xd0f1
MISSION_SPARE equ 0xd0f2
MISSION_TICK_TURNS equ 120      ; a tick, in wait turns (1.2 ms)
MISSION_TICK_NEED equ 200       ; a tick and a margin (2 ms)
MISSION_TICKS_MAX equ 6         ; ticks owed at most (0.1 s late)
MISSION_TICK_NOTES equ 260      ; one that reads new notes (up to 2.3 ms)
PSG_NOTE_COUNT equ 0xe183       ; driver: new notes when it is 1 before a tick
MISSION_OVERRUN equ 1100        ; more turns: the frame was lost (a normal one has up to about 900)
mission_frame_tick:
        ld hl,(0xfc9e)
        inc hl
        ld (0xfc9e),hl
        ld a,(0xfda1)
        cp PSG_CALL_HOOK
        ret nz                  ; no music installed (standalone mission)
        ld hl,PSG_CALL_DEFER+1
        ld a,(hl)
        or a
        jr nz,.cycle
        ld (hl),6
.cycle:
        dec (hl)
        jr nz,.owed
        ld (hl),6
        jr .decide
.owed:
        ld hl,MISSION_TICKS
        ld a,(hl)
        cp MISSION_TICKS_MAX
        jr nc,.decide
        inc (hl)
.decide:
        ld a,(PSG_CALL_ARC_ON)
        or a
        ret nz                  ; an arcade song (the ending) has the PSG
        ld a,(PSG_SFX_ON)
        or a
        jr nz,.effect
        ld (MISSION_TICKED),a   ; only the music (about 0.12 ms a tick):
.cheap:                         ; every owed tick now
        ld hl,MISSION_TICKS
        ld a,(hl)
        or a
        ret z
        dec (hl)
        call mission_music_tick
        jr .cheap
.effect:                        ; the driver plays the effect: as before
        ld hl,(MISSION_SPARE)
        ld de,-MISSION_OVERRUN
        add hl,de
        jr nc,.counted
        xor a                   ; the last frame overran: the wait counted a
        ld (MISSION_TICKED),a   ; whole extra frame; no tick now
        ret
.counted:
        ld hl,(MISSION_SPARE)   ; spare turns this frame would have, no tick
        ld a,(MISSION_TICKED)
        or a
        jr z,.predicted
        ld e,a
        ld d,0
.add_back:
        ld bc,MISSION_TICK_TURNS
        add hl,bc
        dec e
        jr nz,.add_back
.predicted:
        xor a
        ld (MISSION_TICKED),a
.tick:
        ld a,(MISSION_TICKS)
        or a
        ret z
        push hl
        ld de,-MISSION_TICK_NEED
        ld a,(PSG_NOTE_COUNT)
        dec a
        jr nz,.need
        ld de,-MISSION_TICK_NOTES
.need:
        add hl,de
        pop hl
        jr c,.room
        ld a,(MISSION_TICKS)    ; no room: the tick waits, unless the music
        cp MISSION_TICKS_MAX    ; is already 0.1 s late (a typical tick fits)
        ret c
        ld a,(MISSION_TICKED)
        or a
        ret nz                  ; at most one tick then
.room:
        ld de,-MISSION_TICK_TURNS
        add hl,de               ; room left after this tick
        push hl
        ld hl,MISSION_TICKS
        dec (hl)
        ld hl,MISSION_TICKED
        inc (hl)
        call mission_music_tick
        pop hl
        ld a,(MISSION_TICKED)
        cp 2
        jr c,.tick              ; a second tick to catch up, if there is room
        ret

; The mission's music without the Spectrum driver: its song 8 as the
; registers R0..R10 tick by tick (tools/build_mission_music.py), in bank 26
; from MISSION_MUSIC. A tick reads one (mapping bank 26 at page 2 for a
; moment; C839 keeps the mission's bank there) and writes the 11 registers.
; While an effect plays (PSG_SFX_ON) the driver ticks too, before it: the
; effect has channel C (R4, R5, R6, R10, R7 bits 2 and 5; the driver writes
; every register, the music writes A and B back over it).
        include "../psg/mission-music.inc"
        include "../psg/driver.inc"
MUSIC_PTR equ 0xd400            ; the next tick (the arcade songs' buffer:
MUSIC_REGS equ 0xd402           ; free in the mission); R0..R10
PSG_DRIVER_R7 equ PSG_BASE+0x3ab ; the driver's R7 (Spectrum C3ABh)
mission_music_start:
        ld hl,MISSION_MUSIC
        ld (MUSIC_PTR),hl
        ret
mission_music_tick:
        ld a,(PSG_SFX_ON)
        or a
        call nz,PSG_CALL_TICK   ; the effect first: it writes every register
        ld a,MISSION_MUSIC_BANK
        ld (0x7000),a
        ld hl,(MUSIC_PTR)
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,d
        inc a
        jr nz,.mask
        ld hl,MISSION_MUSIC_LOOP
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
.mask:
        ld bc,MUSIC_REGS
.read:
        srl d
        rr e
        jr nc,.kept
        ld a,(hl)
        inc hl
        ld (bc),a
.kept:
        inc c
        ld a,c
        cp low (MUSIC_REGS+11)
        jr nz,.read
        ld (MUSIC_PTR),hl
        ld a,(0xc839)
        ld (0x7000),a           ; the mission's bank back
        ld a,(PSG_SFX_ON)
        ld b,a
        ld hl,MUSIC_REGS
        ld c,0
.write:
        ld e,(hl)
        inc b
        dec b
        jr z,.out
        ld a,c                  ; an effect: channel C stays the driver's
        cp 4
        jr z,.skip
        cp 5
        jr z,.skip
        cp 6
        jr z,.skip
        cp 10
        jr z,.skip
        cp 7
        jr nz,.out
        ld a,(PSG_DRIVER_R7)
        and 0x24
        ld d,a
        ld a,e
        and 0xdb
        or d
        ld e,a
.out:
        ld a,c
        out (0xa0),a
        ld a,e
        out (0xa1),a
.skip:
        inc hl
        inc c
        ld a,c
        cp 11
        jr nz,.write
        ret
