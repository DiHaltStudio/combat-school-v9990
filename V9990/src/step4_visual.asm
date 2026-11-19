; Standalone Firing Range II prototype, MSX + V9990 B1.
        org 0x4000
        db "AB"
        dw init
        dw 0,0,0
        ds 6,0
init:
        di
        call 0x0138
        rrca
        rrca
        and 3
        ld c,a
        ld b,0
        ld hl,0xfcc1
        add hl,bc
        ld a,(hl)
        and 0x80
        or c
        ld c,a
        bit 7,a
        jr z,.slot_ready
        ; HL points at EXPTBL[primary]. The corresponding SLTTBL
        ; entry gives page 1's subslot in the ENASLT ID's bits 3..2.
        inc hl
        inc hl
        inc hl
        inc hl
        ld a,(hl)
        and 0x0c
        or c
.slot_ready:
        ld h,0x80
        call 0x0024
        di
        xor a
        ld (0xf3db),a          ; BIOS CLIKSW: disable the keyboard click
        ld sp,0xf000
        call display_off        ; off before the reset, which shows P1 garbage
        ld a,2
        out (0x67),a
        xor a
        out (0x67),a
        out (0x6f),a
        ld a,6
        out (0x64),a
        ld hl,regs
        ld bc,0x0463
        otir
        ld a,13
        out (0x64),a
        ld hl,settings
        ld bc,0x0863
        otir
        ; Field at y=512 from two ASCII16 banks.
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        ld a,1
        out (0x63),a
        ld a,1
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ld a,2
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ; Character, vehicles, digits and filled cells at y=768.
        xor a
        out (0x64),a
        out (0x63),a
        ld a,0x80
        out (0x63),a
        ld a,1
        out (0x63),a
        ld a,3
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        xor a
        ld (0xc803),a
        ld (0xc807),a
        ld (0xc809),a
        ld (0xc80a),a
        ld (0xc80c),a
        ld (0xc808),a
        ld (0xc85a),a
        ld (0xc8e2),a
        ld (0xc8ec),a
        ld (0xc8ee),a
        ld (0xc8f6),a
        ld (0xc8f9),a
        ld (0xc8fb),a
        ld (0xc883),a
        ld hl,0xca00
        ld de,0xca01
        ld bc,23
        ld (hl),a
        ldir
        ld hl,0
        ld (0xc8e4),hl
        ld hl,0xc900
        ld de,0xc901
        ld bc,15
        ld (hl),a
        ldir
        ; One byte per recorded track remembers a successful hit.
        ld hl,0xc980
        ld de,0xc981
        ld bc,127
        ld (hl),a
        ldir
        ld hl,0x8000
        ld (0xc8e6),hl
        ld a,4
        ld (0xc8e8),a
        ld (0x7000),a
        ld a,110
        ld (0xc800),a
        ld a,39
        ld (0xc806),a
        ld hl,(0xfc9e)
        ld (0xc81a),hl
        ld a,(0x002b)
        bit 7,a
        ld a,60
        jr z,.hz_ready
        ld a,50
.hz_ready:
        ld (0xc81c),a
        ; Jiffies per tenth of a second: 6 at 60 Hz, 5 at 50 Hz.
        ld b,-1
.tenth_rate:
        inc b
        sub 10
        jr nc,.tenth_rate
        ld a,b
        ld (0xc882),a
        ld hl,(0xfc9e)
        ld (0xc8e0),hl
        ; Standalone test ROM only (tools/build_step4_integrated.py removes
        ; it): the game score starts at zero.
        xor a
        ld (0xc75c),a
        ld (0xc75d),a
        ld (0xc75e),a
        ld a,3                  ; Firing Range II music (src/psg_calls.asm)
        call psg_play
        ei
loop:
        ld a,(0xc80c)
        or a
        jr z,.playing
        call result_input
        jr .draw
.playing:
        call clock
        call controls
        call advance_shots
        call advance_wave
.draw:
        call draw
        call display_wait_command
.wait_end:
        di                      ; no interrupt between the blank and the page (music)
        in a,(0x65)
        bit 6,a
        jr nz,.wait_end
.wait_start:
        in a,(0x65)
        bit 6,a
        jr z,.wait_start
        ld a,18
        out (0x64),a
        ld a,(0xc80a)
        out (0x63),a
        xor 1
        ld (0xc80a),a
        ld hl,palette
        call display_first_palette
        call animate_robot_panel
        ei
        jp loop
        define DISPLAY_STAGE_HELPERS
        include "psg_calls.asm"   ; music calls, out of the flow
 ; The arcade alternates the magenta panel between bright and dark purple.
 ; Only robots use palette index 11. R14 uses four addresses per entry.
animate_robot_panel:
        ld a,(0xfc9e)
        and 8
        ld (0xc8f5),a
        ld a,14
        out (0x64),a
        ld a,44
        out (0x63),a
        ld a,(0xc8f5)
        or a
        jr z,.panel_bright
        ld a,11
        out (0x61),a
        ld a,1
        out (0x61),a
        ld a,12
        out (0x61),a
        ret
.panel_bright:
        ld a,26
        out (0x61),a
        ld a,3
        out (0x61),a
        ld a,20
        out (0x61),a
        ret
result_input:
        xor a
        call 0x00d8
        or a
        jr nz,.pressed
        ld a,1
        call 0x00d8
.pressed:
        or a
        jr nz,.restart
        ld a,1
        ld (0xc808),a
        ret
.restart:
        ld a,(0xc808)
        or a
        ret z
        jp init
; The arcade clock shows 0:SS.t: c806 seconds, c883 tenths. At zero the
; result starts and c880 keeps its jiffy for the qualified sequence.
clock:
        ld hl,(0xfc9e)
        ld de,(0xc81a)
        or a
        sbc hl,de
        ld a,(0xc882)
        ld e,a
        ld d,0
        sbc hl,de
        ret c
        ld hl,(0xc81a)
        add hl,de
        ld (0xc81a),hl
        ld a,(0xc883)
        sub 1
        jr nc,.tenth
        ld hl,0xc806
        dec (hl)
        ld a,(hl)               ; S.9 shown: a warning below 6 s (Spectrum)
        inc a
        call psg_countdown
        ld a,9
.tenth:
        ld (0xc883),a
        ld hl,0xc806
        or (hl)
        ret nz
        ld a,SFX_TIME_UP
        call psg_sfx
        ld a,(0xc809)
        cp 52
        ld a,2
        jr c,.end
        ld a,1
.end:
        ld (0xc80c),a
        ld hl,(0xfc9e)
        ld (0xc880),hl
        ret
; HL = jiffies since the end of the test.
result_time:
        ld hl,(0xfc9e)
        ld de,(0xc880)
        or a
        sbc hl,de
        ret
controls:
        xor a
        ld (0xc8f9),a
        call 0x00d5
        or a
        jr nz,.dir
        ld a,1
        call 0x00d5
.dir:
        cp 3
        jp z,.right
        cp 7
        jr nz,.fire
        ld a,(0xc800)
        cp 3
        jr c,.fire
        sub 3
        ld (0xc800),a
        ld a,2
        ld (0xc8f9),a
        jr .fire
.right:
        ld a,(0xc800)
        cp 222
        jr nc,.fire
        add a,3
        ld (0xc800),a
        ld a,1
        ld (0xc8f9),a
.fire:
        xor a
        call 0x00d8
        or a
        jr nz,.triggered
        ld a,1
        call 0x00d8
.triggered:
        or a
        ret z
        ; Limit autofire by the BIOS clock, independent of drawing speed.
        ld a,(0xc8fb)
        or a
        jr z,.find_shot
        ld a,(0xfc9e)
        ld b,a
        ld a,(0xc8fa)
        ld c,a
        ld a,b
        sub c
        cp 4
        ret c
.find_shot:
        ld a,(0xc803)
        or a
        jr nz,.find_extra
        ld a,1
        ld (0xc803),a
        ld a,(0xc800)
        add a,14
        ld (0xc801),a
        ld a,150
        ld (0xc802),a
        jr .shot_started
.find_extra:
        ld ix,0xca00
        ld b,7
.find_slot:
        ld a,(ix+2)
        or a
        jr z,.start_extra
        ld de,3
        add ix,de
        djnz .find_slot
        ret
.start_extra:
        ld (ix+2),1
        ld a,(0xc800)
        add a,14
        ld (ix+0),a
        ld (ix+1),150
.shot_started:
        ld a,SFX_SHOT           ; each shot (Spectrum)
        call psg_sfx
        ld a,(0xfc9e)
        ld (0xc8fa),a
        ld a,1
        ld (0xc8fb),a
        ret
; The collision routine uses the original first slot. Process the other
; seven through the same routine, preserving that slot between calls.
advance_shots:
        call advance_shot
        ld hl,0xc801
        ld de,0xca20
        ld bc,3
        ldir
        ld ix,0xca00
        ld a,7
        ld (0xc8fc),a
.extra_shot:
        ld a,(ix+0)
        ld (0xc801),a
        ld a,(ix+1)
        ld (0xc802),a
        ld a,(ix+2)
        ld (0xc803),a
        call advance_shot
        ld a,(0xc801)
        ld (ix+0),a
        ld a,(0xc802)
        ld (ix+1),a
        ld a,(0xc803)
        ld (ix+2),a
        ld de,3
        add ix,de
        ld a,(0xc8fc)
        dec a
        ld (0xc8fc),a
        jr nz,.extra_shot
        ld hl,0xca20
        ld de,0xc801
        ld bc,3
        ldir
        ret
advance_shot:
        ld a,(0xc803)
        or a
        ret z
        ld a,(0xc802)
        cp 6
        jp c,.remove
        sub 6
        ld (0xc802),a
        xor a
        ld (0xc80b),a
.check:
        ld a,(0xc80b)
        ld e,a
        ld d,0
        ld hl,0xc900
        add hl,de
        ld a,(hl)
        cp 1
        jp nz,.next
        ld hl,0xc920
        add hl,de
        ld a,(hl)
        ld (0xc80e),a
        ld hl,0xc930
        add hl,de
        ld a,(hl)
        ld (0xc86c),a
        ld a,(0xc80e)
        call target_size
        ld hl,0xc910
        add hl,de
        ld a,(0xc801)
        sub (hl)
        add a,2
        ld b,a
        ld a,(0xc85d)
        add a,2
        cp b
        jp c,.next
        jp z,.next
        ld a,(0xc80e)
        ld b,a
        ld a,(0xc802)
        sub b
        add a,4
        ld b,a
        ld a,(0xc85f)
        add a,4
        cp b
        jp c,.next
        jp z,.next
        ld hl,0xc900
        add hl,de
        ld (hl),0
        ld hl,0xc910
        add hl,de
        ld a,(hl)
        ld (0xc8f7),a
        ld a,(0xc80e)
        ld (0xc8f8),a
        ld a,12
        ld (0xc8f6),a
        ld hl,0xc950
        add hl,de
        ld e,(hl)
        ld d,0
        ld hl,0xc980
        add hl,de
        ld (hl),1
        ld a,SFX_HIT            ; a target hit (Spectrum)
        call psg_sfx
        ld de,100              ; arcade: 100 points per hit
        call add_score
        ld a,(0xc809)
        cp 99
        jr nc,.remove
        inc a
        ld (0xc809),a
.remove:
        xor a
        ld (0xc803),a
        ret
.next:
        ld a,(0xc80b)
        inc a
        ld (0xc80b),a
        cp 16
        jp c,.check
        ret
; The 30 Hz simulation clock is derived from BIOS JIFFY. It stays tied to
; real time even when rendering more robots makes the Z80 loop slower.
advance_wave:
        ld a,(0xc807)
        inc a
        ld (0xc807),a
        ld hl,(0xfc9e)
        ld de,(0xc8e0)
        or a
        sbc hl,de
        ld a,h
        or a
        ld a,6
        jr nz,.delta_ready
        ld a,l
        cp 7
        jr c,.delta_ready
        ld a,6
.delta_ready:
        or a
        ret z
        ld b,a
        ld e,a
        ld d,0
        ld hl,(0xc8e0)
        add hl,de
        ld (0xc8e0),hl
        ; phase += delta * 30 (32*delta - 2*delta), 8-bit is enough.
        ld a,b
        add a,a
        ld c,a
        add a,a
        add a,a
        add a,a
        add a,a
        sub c
        ld b,a
        ld a,(0xc8e2)
        add a,b
        ld (0xc8e2),a
.tick:
        ld a,(0xc81c)
        ld b,a
        ld a,(0xc8e2)
        cp b
        ret c
        sub b
        ld (0xc8e2),a
        call robot_tick
        jr .tick

; Each recorded frame contains visible robot IDs, positions and views. A hit
; marks that ID, so later frames never recreate the destroyed robot.
robot_tick:
        ld a,(0xc8f6)
        or a
        jr z,.no_blast_tick
        dec a
        ld (0xc8f6),a
.no_blast_tick:
        ld a,1
        ld (0xc8f3),a
        ld hl,(0xc8e4)
        inc hl
        ld (0xc8e4),hl
        ld de,1381
        or a
        sbc hl,de
        jr nc,.finished
        ld hl,0xc900
        ld de,0xc901
        ld bc,15
        xor a
        ld (hl),a
        ldir
        call sequence_byte
        ld (0xc8ed),a
        xor a
        ld (0xc80b),a
.next:
        ld a,(0xc8ed)
        or a
        jr z,.done
        dec a
        ld (0xc8ed),a
        call sequence_byte
        ld (0xc8ef),a
        call sequence_byte
        ld (0xc8f0),a
        call sequence_byte
        ld (0xc8f1),a
        call sequence_byte
        ld (0xc8f2),a
        ld a,(0xc8ef)
        ld e,a
        ld d,0
        ld hl,0xc980
        add hl,de
        ld a,(hl)
        or a
        jr nz,.next
        ld a,(0xc80b)
        ld e,a
        ld d,0
        ld hl,0xc900
        add hl,de
        ld (hl),1
        ld hl,0xc910
        add hl,de
        ld a,(0xc8f0)
        ld (hl),a
        ld hl,0xc920
        add hl,de
        ld a,(0xc8f1)
        ld (hl),a
        ld hl,0xc930
        add hl,de
        ld a,(0xc8f2)
        ld (hl),a
        ld hl,0xc950
        add hl,de
        ld a,(0xc8ef)
        ld (hl),a
        ld a,(0xc80b)
        inc a
        ld (0xc80b),a
        jr .next
.finished:
.done:
        xor a
        ld (0xc8f3),a
        ; The extrapolated tail has finished; do not wrap to the start.
        ret

; Sequential byte reader spanning the two ASCII16 banks used by the trace.
sequence_byte:
        push hl
        ld hl,(0xc8e6)
        ld a,(hl)
        inc hl
        bit 6,h
        jr z,.pointer_ready
        push af
        ld a,(0xc8e8)
        inc a
        ld (0xc8e8),a
        ld (0x7000),a
        ld hl,0x8000
        pop af
.pointer_ready:
        ld (0xc8e6),hl
        pop hl
        ret

; A=world Y; use the same view-specific dimensions for drawing and hits.
; C86C = view (bits 0-1) and size + 1 (bits 2-4): the recording gives each
; robot the size of its arcade sprite (tools/build_step4_robots.py), so the
; image never jumps between sizes; 0 = size from the top line (y bands).
target_size:
        push bc
        push de
        ld b,a
        ld a,(0xc86c)
        rrca
        rrca
        and 7
        jr z,.by_y
        dec a
        ld b,a
        jr .band_ready
.by_y:
        ld a,b
        ld b,0
        ld hl,size_limits
.band:
        cp (hl)
        jr c,.band_ready
        inc hl
        inc b
        jr .band
.band_ready:
        ld a,(0xc86c)
        and 3
        ld e,a
        ld d,0
        ld hl,view_sets
        add hl,de
        ld e,(hl)
        ld hl,target_sets
        add hl,de
        ld a,(hl)
        ld (0xc86d),a
        inc hl
        ld a,b
        add a,a
        add a,b
        ld e,a
        add hl,de
        ld de,0xc85d
        ldi
        ldi
        ldi
        pop de
        pop bc
        ret
; Arcade sizes by depth (top row): 144, 146, 148, 152 and 160 for the front.
size_limits: db 57,71,85,100,255
; Views 0 front, 1 side facing right, 2 side facing left, 3 rear (front).
view_sets: db 0,16,32,0
; Arcade shooter pose (x in the strip at VRAM y 724): idle, walking right
; and left (two steps each), and when qualified, after the time is up,
; standing up after half a second and raising his arm after one second.
player_frame:
        ld a,(0xc80c)
        or a
        jr z,.walk
        dec a
        ld a,0
        ret nz
        call result_time
        ld a,(0xc81c)
        ld e,a
        ld d,0
        sbc hl,de
        ld a,192
        ret nc
        add hl,de
        srl e
        or a
        sbc hl,de
        ld a,160
        ret nc
        xor a
        ret
.walk:
        ld a,(0xc8f9)
        or a
        ret z
        dec a
        ld b,32
        jr z,.direction
        ld b,96
.direction:
        ld a,(0xc807)
        and 8
        add a,a
        add a,a
        add a,b
        ret
; DE = points added to the game score C75C..C75E (24 bits, little endian).
add_score:
        ld hl,(0xc75c)
        add hl,de
        ld (0xc75c),hl
        ret nc
        ld hl,0xc75e
        inc (hl)
        ret

; Single game score at the top right (the clock is at x 72): red 1P at
; x 152 and the total left-aligned from x 176, leading zeros hidden.
draw_score:
        ld hl,label_1p
        call label_blit
        ld hl,(0xc75c)
        ld a,(0xc75e)
        ld e,a                  ; E:HL = score
        ld ix,score_powers
        ld d,176
        ld c,0
.digit:
        ld b,0xff
.subtract:
        inc b
        ld a,l
        sub (ix+0)
        ld l,a
        ld a,h
        sbc a,(ix+1)
        ld h,a
        ld a,e
        sbc a,(ix+2)
        ld e,a
        jr nc,.subtract
        ld a,l
        add a,(ix+0)
        ld l,a
        ld a,h
        adc a,(ix+1)
        ld h,a
        ld a,e
        adc a,(ix+2)
        ld e,a
        ld a,b
        or c
        ld c,a
        jr z,.hidden
        push bc
        push de
        push hl
        push ix
        ld a,d
        ld (0xc80d),a
        ld a,b
        call draw_digit
        pop ix
        pop hl
        pop de
        pop bc
        ld a,d
        add a,8
        ld d,a
.hidden:
        inc ix
        inc ix
        inc ix
        ld a,(ix+0)
        or a
        jr nz,.digit
        ld a,d
        ld (0xc80d),a
        ld a,l
        jp draw_digit
score_powers:
        db 0xa0,0x86,0x01, 0x10,0x27,0x00, 0xe8,0x03,0x00
        db 0x64,0x00,0x00, 0x0a,0x00,0x00, 0
label_1p:       db 208,28,16,10,152,16

; HL = label: atlas x and y (page 768), width, height, screen x and y.
label_blit:
        push hl
        ld hl,result_template
        call copy_command
        pop hl
        ld de,0xc300
        ldi
        inc de
        ldi
        ld de,0xc308
        ldi
        inc de
        ldi
        ld de,0xc304
        ldi
        inc de
        ldi
        ld a,(0xc80a)
        ld (0xc307),a
        ld hl,0xc300
        jp command
; Arcade positions moved 14 lines up, as the field.
label_blew_it:  db 120,100,88,10,24,106
label_made_it_top: db 112,28,88,10,24,34
label_player:   db 0,28,64,10,32,72
label_nick:     db 64,28,48,10,40,84
label_made_it:  db 112,28,88,10,24,106
; Commands: 21 bytes at c300, same V9990 hardware path as the other demos.
draw:
        ld hl,field_template
        call copy_command
        ld a,(0xc80a)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld hl,player_template
        call copy_command
        call player_frame
        ld (0xc300),a
        ld a,(0xc800)
        ld (0xc304),a
        ld a,(0xc80a)
        ld (0xc307),a
        ld hl,0xc300
        call command
        xor a
        ld (0xc80b),a
.targets:
        ld a,(0xc80b)
        ld e,a
        ld d,0
        ld hl,0xc900
        add hl,de
        ld a,(hl)
        cp 1
        jr nz,.next_target
        ld hl,0xc910
        add hl,de
        ld a,(hl)
        ld (0xc80d),a
        ld hl,0xc920
        add hl,de
        ld a,(hl)
        ld (0xc80e),a
        ld hl,0xc930
        add hl,de
        ld a,(hl)
        ld (0xc86c),a
        ld a,(0xc80e)
        call target_size
        ld hl,target_template
        call copy_command
        ld a,(0xc85e)
        ld (0xc300),a
        ld a,(0xc86d)
        ld (0xc302),a
        ; Keep the V9990 copy inside the 256-pixel scanline.
        ld a,(0xc80d)
        ld b,a
        ld a,(0xc85d)
        add a,b
        jr c,.target_clip
        ld a,(0xc85d)
        jr .target_width_ready
.target_clip:
        xor a
        sub b
.target_width_ready:
        ld (0xc8f4),a
        ld (0xc308),a
        ld a,(0xc85f)
        ld (0xc30a),a
        ld a,(0xc80d)
        ld (0xc304),a
        ld a,(0xc80e)
        ld (0xc306),a
        ld a,(0xc80a)
        ld (0xc307),a
        ld hl,0xc300
        call command
.next_target:
        ld a,(0xc80b)
        inc a
        ld (0xc80b),a
        cp 16
        jr c,.targets
        ld a,(0xc8f6)
        or a
        jr z,.draw_bullet
        ld hl,blast_template
        call copy_command
        ld a,(0xc8f6)
        ld b,a
        ld a,128
        ld c,a
        ld a,b
        cp 9
        jr nc,.blast_frame
        ld c,144
        cp 5
        jr nc,.blast_frame
        ld c,160
.blast_frame:
        ld a,c
        ld (0xc300),a
        ld a,(0xc8f7)
        cp 241
        jr c,.blast_x_ready
        ld a,240
.blast_x_ready:
        ld (0xc304),a
        ld a,(0xc8f8)
        ld (0xc306),a
        ld a,(0xc80a)
        ld (0xc307),a
        ld hl,0xc300
        call command
.draw_bullet:
        ld a,(0xc803)
        or a
        jr z,.extra_bullets
        ld hl,bullet_template
        call copy_command
        ld a,(0xc801)
        ld (0xc304),a
        ld a,(0xc802)
        ld (0xc306),a
        ld a,(0xc80a)
        ld (0xc307),a
        ld hl,0xc300
        call command
.extra_bullets:
        ld ix,0xca00
        ld a,7
        ld (0xc8fd),a
.extra_bullet:
        ld a,(ix+2)
        or a
        jr z,.next_bullet
        ld hl,bullet_template
        call copy_command
        ld a,(ix+0)
        ld (0xc304),a
        ld a,(ix+1)
        ld (0xc306),a
        ld a,(0xc80a)
        ld (0xc307),a
        ld hl,0xc300
        call command
.next_bullet:
        ld de,3
        add ix,de
        ld a,(0xc8fd)
        dec a
        ld (0xc8fd),a
        jr nz,.extra_bullet
.hud:
        ld a,(0xc80c)
        cp 2
        jr nz,.not_lost
        ; Lost (arcade): PLAYER 1 (NICK) / YOU BLEW IT in red.
        ld hl,label_player
        call label_blit
        ld hl,label_nick
        call label_blit
        ld hl,label_blew_it
        jr .label
.not_lost:
        dec a
        jr z,.result_labels
        ; Qualified during the test: the label blinks as in the arcade.
        ld a,(0xc809)
        cp 52
        jr c,.no_result
        ld a,(0xfc9e)
        and 8
        jr nz,.no_result
.top_label:
        ld hl,label_made_it_top
.label:
        call label_blit
        jr .no_result
.result_labels:
        call result_time
        ld a,(0xc81c)
        ld e,a
        srl a
        add a,e
        ld e,a
        ld d,0
        or a
        sbc hl,de
        jr c,.top_label
        ld hl,label_player
        call label_blit
        ld hl,label_nick
        call label_blit
        ld hl,label_made_it
        jr .label
.no_result:
        ld a,(0xc806)
        ld c,72
        call draw_number
        ld a,96
        ld (0xc80d),a
        ld a,(0xc883)
        call draw_digit
        ld a,(0xc809)
        ld c,8
        call draw_number
        call draw_score
        ld a,(0xc809)
        cp 26
        jr c,.first_grid
        ld a,26
.first_grid:
        call draw_grid
        ld a,(0xc809)
        cp 26
        ret c
        sub 26
        cp 27
        jr c,.second_grid
        ld a,26
.second_grid:
        ld c,201
        call grid_at
        ld a,(0xc809)
        cp 52
        ret c
        sub 52
        cp 27
        jr c,.third_grid
        ld a,26
.third_grid:
        ld c,205
        call grid_at
        ld a,(0xc809)
        cp 78
        ret c
        sub 78
        cp 27
        jr c,.fourth_grid
        ld a,26
.fourth_grid:
        ld c,209
        jp grid_at
; A=number of filled cells in first line.
draw_grid:
        ld c,197
grid_at:
        or a
        ret z
        add a,a
        add a,a
        ld (0xc81d),a
        ld a,c
        ld (0xc81e),a
        ld hl,grid_template
        call copy_command
        ld a,(0xc81d)
        ld (0xc308),a
        ld a,(0xc81e)
        ld (0xc306),a
        ld a,(0xc80a)
        ld (0xc307),a
        ld hl,0xc300
        jp command
; A=two-digit value, C=destination x, at top for clock or bottom for hits.
draw_number:
        ld b,0
.digits:
        cp 10
        jr c,.ones
        sub 10
        inc b
        jr .digits
.ones:
        ld (0xc80f),a
        ld a,c
        ld (0xc80d),a
        ld a,b
        call draw_digit
        ld a,(0xc80d)
        add a,8
        ld (0xc80d),a
        ld a,(0xc80f)
        jp draw_digit
draw_digit:
        add a,a
        add a,a
        add a,a
        add a,64
        ld (0xc81d),a
        ld hl,digit_template
        call copy_command
        ld a,(0xc81d)
        ld (0xc300),a
        ld a,(0xc80d)
        ld (0xc304),a
        cp 48
        ld a,179
        jr c,.digit_y
        ld a,16
.digit_y:
        ld (0xc306),a
        ld a,(0xc80a)
        ld (0xc307),a
        ld hl,0xc300
        jp command
copy_command:
        ld de,0xc300
        ld bc,21
        ldir
        ret
upload:
        ld bc,0x0060
        otir
        dec d
        jr nz,upload
        ret
command:
.wait:
        in a,(0x65)
        rrca
        jr c,.wait
        ld a,32
        out (0x64),a
        ld bc,21*256+0x63
        otir
        ret
field_template:
        dw 0,512,0,0,256,212
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
player_template:
        dw 0,724,0,134,32,60
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
target_template:
        dw 112,800,0,0,8,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
bullet_template:
        dw 112,816,0,0,4,6
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
blast_template:
        dw 128,816,0,0,16,16
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
result_template:
        dw 184,816,112,20,32,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
digit_template:
        dw 64,784,0,0,8,10
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
grid_template:
        dw 0,816,8,197,104,3
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
target_sets: incbin "../build/step4/target-sets.bin"
regs:   db 0x81,0,0x42,0
settings: db 0,0,0,0,0,0,0,0
palette: incbin "../build/step4/palette.bin"
        assert $ <= 0x8000
        ds 0x8000-$,0xff
        incbin "../build/step4/field.bin"
        incbin "../build/step4/atlas.bin"
        ds 0x14000-$,0xff
        incbin "../build/step4/recorded-sequence.bin"
        ds 0x1c000-$,0xff
