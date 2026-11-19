; Integrated Step 3 -> bonus -> running interlude -> three-step map -> Step 4.
; This code is included only in the MegaROM build of Step 3.
; Called each frame after the player has finished successfully.
; Entry at 400Ah in the integrated cartridge, after Step 4 has ended.
step4_transition:
        di
        ld a,(0xc81c)
        ld (0xc734),a
        ld a,(0xc809)
        ld b,0
        cp 54
        jr c,.bracket
        inc b
        cp 56
        jr c,.bracket
        inc b
        cp 58
        jr c,.bracket
        inc b
        cp 60
        jr c,.bracket
        inc b
        cp 64
        jr c,.bracket
        inc b
.bracket:
        ld a,b
        ld (0xc736),a
        add a,a
        ld e,a
        ld d,0
        ld hl,step4_bonus_points
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,(0xc75c)
        add hl,de
        ld (0xc75c),hl
        ld a,(0xc75e)
        adc a,0
        ld (0xc75e),a
        call display_off        ; off from the next frame on
        ld hl,transition_bonus_palette
        call transition_palette
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        ld (0xc0b6),a
        ld a,9                  ; bonus music
        call psg_play
        ld a,83
        call transition_screen
        ld a,(0xc736)
        call transition_marker
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld a,12
        ld (0xc418),a
        ei
        ld a,4
        call transition_wait_seconds
        di
        call display_off        ; off from the next frame on
        ld hl,transition_map_palette
        call transition_palette
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        ld a,1
        ld (0xc0b6),a
        call psg_wait_song      ; the bonus music ends first
        call psg_stop           ; the map is silent
        ld a,62
        call transition_screen
        ld a,1
        call transition_map_light
        call wait_cmd
        ld a,122
        ld (0xc306),a
        ld a,29                 ; the map's squares: 29 lines
        ld (0xc30a),a
        ld hl,0xc300
        call command
        call wait_cmd
        ld a,92
        ld (0xc306),a
        ld hl,0xc300
        call command
        call wait_cmd
        xor a
        ld (0xc0b6),a
        ld a,62
        call transition_screen
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld a,13
        ld (0xc418),a
        ei
        ld hl,(0xfc9e)
        ld (0xc768),hl
.map_wait:
        halt
        ld a,(0xfc9e)
        and 16
        rrca
        rrca
        rrca
        rrca
        ld b,a
        ld a,18
        out (0x64),a
        ld a,b
        out (0x63),a
        ld hl,(0xfc9e)
        ld de,(0xc768)
        or a
        sbc hl,de
        push hl
        ld a,(0xc734)
        ld e,a
        ld d,0
        ld h,d
        ld l,e
        add hl,hl
        add hl,hl
        add hl,de
        ex de,hl
        pop hl
        or a
        sbc hl,de
        jr c,.map_wait
        di
        call display_map_off
        ld hl,step5_trampoline
        ld de,0xca80
        ld bc,step5_trampoline_end-step5_trampoline
        ldir
        jp 0xca80
step5_trampoline:
        ld a,85
        ld (0x6000),a
        jp 0x4010
step5_trampoline_end:
step4_bonus_points: dw 0,1000,2000,4000,6000,8000

; Both outcomes complete Step 5. Keep the five-step map until Step 6 exists.
step5_transition:
        di
        call display_off        ; off from the next frame on
        ld hl,transition_map_palette
        call transition_palette
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        ld a,1
        ld (0xc0b6),a
        call psg_wait_song      ; the bonus music ends first
        call psg_stop           ; the map is silent
        ld a,62
        call transition_screen
        ld a,1
        call transition_map_light
        call wait_cmd
        ld a,122
        ld (0xc306),a
        ld a,29                 ; the map's squares: 29 lines
        ld (0xc30a),a
        ld hl,0xc300
        call command
        call wait_cmd
        ld a,92
        ld (0xc306),a
        ld hl,0xc300
        call command
        call wait_cmd
        ld a,62
        ld (0xc306),a
        ld hl,0xc300
        call command
        call wait_cmd
        xor a
        ld (0xc0b6),a
        ld a,62
        call transition_screen
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld a,16
        ld (0xc418),a
        ei
        ld hl,(0xfc9e)
        ld (0xc768),hl
.map_wait:
        halt
        ld a,(0xfc9e)
        and 16
        rrca
        rrca
        rrca
        rrca
        ld b,a
        ld a,18
        out (0x64),a
        ld a,b
        out (0x63),a
        ld hl,(0xfc9e)
        ld de,(0xc768)
        or a
        sbc hl,de
        push hl
        ld a,(0xc734)
        ld e,a
        ld d,0
        ld h,d
        ld l,e
        add hl,hl
        add hl,hl
        add hl,de
        ex de,hl
        pop hl
        or a
        sbc hl,de
        jr c,.map_wait
        di
        call display_map_off
        ld hl,step6_trampoline
        ld de,0xca80
        ld bc,step6_trampoline_end-step6_trampoline
        ldir
        jp 0xca80
step6_trampoline:
        xor a
        ld (0x6000),a
        jp 0x400a
step6_trampoline_end:

transition_poll:
        ld a,(0xc760)
        or a
        jr nz,.waiting
        inc a
        ld (0xc760),a
        ld hl,(0xfc9e)
        ld (0xc761),hl
.waiting:
        ld hl,(0xfc9e)
        ld de,(0xc761)
        or a
        sbc hl,de
        ; Six seconds at the goal: the runner turns, pants and raises his arm.
        push hl
        ld a,(0xc734)
        ld e,a
        ld d,0
        ld h,d
        ld l,e
        add hl,hl
        add hl,de
        add hl,hl
        ex de,hl
        pop hl
        or a
        sbc hl,de
        ret c
        jp step3_transition

step3_transition:
        di
        ; Carry the race bonus into the running total, with a third byte.
        ld hl,(0xc75c)
        ld de,(0xc739)
        add hl,de
        ld (0xc75c),hl
        ld a,(0xc75e)
        adc a,0
        ld (0xc75e),a
        call display_off        ; off from the next frame on
        ld hl,transition_bonus_palette
        call transition_palette
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        xor a
        ld (0xc0b6),a
        ld a,9                  ; bonus music
        call psg_play
        ld a,58
        call transition_screen
        ld a,(0xc736)
        call transition_marker
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld a,8
        ld (0xc418),a
        ei
        ld a,4
        call transition_wait_seconds
        call psg_wait_song      ; the bonus music ends, then the cadets'
        call transition_animation
        di
        call display_off        ; off from the next frame on
        ld hl,transition_map_palette
        call transition_palette
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        ld a,1
        ld (0xc0b6),a
        call psg_wait_song      ; the bonus music ends first
        call psg_stop           ; the map is silent
        ld a,62
        call transition_screen
        ld a,1
        call transition_map_light
        call wait_cmd
        ld a,122
        ld (0xc306),a
        ld a,29                 ; the map's squares: 29 lines
        ld (0xc30a),a
        ld hl,0xc300
        call command
        call wait_cmd
        xor a
        ld (0xc0b6),a
        ld a,62
        call transition_screen
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld a,10
        ld (0xc418),a
        ei
        ld hl,(0xfc9e)
        ld (0xc768),hl
.map_loop:
        halt
        ld a,(0xfc9e)
        and 16
        rrca
        rrca
        rrca
        rrca
        ld b,a
        ld a,18
        out (0x64),a
        ld a,b
        out (0x63),a
        ld hl,(0xfc9e)
        ld de,(0xc768)
        or a
        sbc hl,de
        push hl
        ld a,(0xc734)
        ld e,a
        ld d,0
        ld h,d
        ld l,e
        add hl,hl
        add hl,hl
        add hl,de              ; five seconds
        ex de,hl
        pop hl
        or a
        sbc hl,de
        jr c,.map_loop
        ; Switching page 1 executes a RAM trampoline until Step 4 is mapped.
        di
        call display_map_off
        ld hl,transition_trampoline
        ld de,0xca80
        ld bc,transition_trampoline_end-transition_trampoline
        ldir
        jp 0xca80
transition_trampoline:
        ld a,77
        ld (0x6000),a
        jp 0x4010
transition_trampoline_end:

; A=picture key (its old first bank) of a 256x212 shared screen, page c0b6.
transition_screen:
        ld (0xc767),a
        xor a
        out (0x64),a
        out (0x63),a
        ld a,(0xc0b6)
        rrca
        out (0x63),a
        xor a
        out (0x63),a
        ld a,(0xc767)
        call transition_stream
        ld a,18
        out (0x64),a
        ld a,(0xc0b6)
        out (0x63),a
        ret
; A = picture key in image_table (tools/build_image_pack.py): its RLE stream
; to the current VRAM address. Leaves the bank of the picture's extra data
; mapped, its bank in C0C8 and address in C0C9. Same as src/demo_b1.asm.
transition_stream:
        ld hl,image_table
.find:
        cp (hl)
        jr z,.found
        ld de,7
        add hl,de
        jr .find
.found:
        inc hl
        ld a,(hl)
        ld (0xc0cb),a
        ld (0x7000),a
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        ld (0xc0c8),a
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld (0xc0c9),bc
        ex de,hl
        ld c,0x60
.read_unit:
        ld a,(hl)
        inc hl
        or a
        jr z,.done
        jp p,.literal
        sub 128
        jr z,.next_bank
        ld b,a
        ld a,(hl)
        inc hl
        ld e,a
        ld a,b
        and 3
        ld d,a
        srl b
        srl b
        ld a,e
        jr z,.rest
.four:
        out (c),a
        out (c),a
        out (c),a
        out (c),a
        djnz .four
.rest:
        ld b,d
        inc b
        dec b
        jr z,.read_unit
.one:
        out (c),a
        djnz .one
        jr .read_unit
.literal:
        ld b,a
        otir
        jr .read_unit
.next_bank:
        ld a,(0xc0cb)
        inc a
        ld (0xc0cb),a
        ld (0x7000),a
        ld hl,0x8000
        jr .read_unit
.done:
        ld a,(0xc0c8)
        ld (0x7000),a
        ret
transition_palette:
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ld bc,0x3061
        otir
        ret
; A seconds, up to five; uses the Step 3 50/60Hz rate.
transition_wait_seconds:
        ld b,a
        ld hl,0
        ld a,(0xc734)
        ld e,a
        ld d,0
.wait_multiply:
        add hl,de
        djnz .wait_multiply
        ld (0xc76b),hl
        ld hl,(0xfc9e)
        ld (0xc768),hl
.wait:
        halt
        ld hl,(0xfc9e)
        ld de,(0xc768)
        or a
        sbc hl,de
        ld de,(0xc76b)
        or a
        sbc hl,de
        jr c,.wait
        ret

transition_marker:
        push af
        ld e,a
        ld d,0
        ld hl,transition_marker_rows
        add hl,de
        ld l,(hl)
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl              ; y * 128 bytes
        ld de,104              ; x = 208 pixels
        add hl,de
        push hl
        pop bc
        pop af                 ; original bracket passed by caller
        push bc                ; preserve destination across source setup
        ld e,a
        ld d,0
        ld h,d
        ld l,e
        add hl,hl
        add hl,hl
        add hl,hl
        push hl                ; index * 8
        add hl,hl
        add hl,hl
        push hl                ; index * 32
        add hl,hl              ; index * 64
        pop de
        add hl,de
        pop de
        add hl,de              ; index * 104: 8 rows of 13 bytes
        ld de,(0xc0c9)         ; extra data of the picture (transition_stream)
        add hl,de
        push hl
        pop ix
        ld a,(0xc0c8)
        ld (0x7000),a
        pop hl                 ; destination byte address in page 0
        call wait_cmd
        ld c,8
.marker_row:
        xor a
        out (0x64),a
        ld a,l
        out (0x63),a
        ld a,(0xc0b6)
        rrca
        or h
        out (0x63),a
        xor a
        out (0x63),a
        ld b,13                ; the arcade's arrow and 1P: 26 pixels
.marker_byte:
        ld a,(ix+0)
        out (0x60),a
        inc ix
        djnz .marker_byte
        ld de,128
        add hl,de
        dec c
        jr nz,.marker_row
        ret
transition_marker_rows:
        db 197,181,165,149,133,117   ; the arcade's rows (tools/build_progress_assets.py)

; Draw completed map squares white in the hidden page. A=0 for Step 1,
; A=1 for Steps 1 and 2; the off page remains the common gold base image.
transition_map_light:
        ld (0xc0b7),a
        ld hl,transition_square
        ld de,0xc300
        ld bc,21
        ldir
        ld a,(0xc0b6)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld a,(0xc0b7)
        or a
        ret z
        call wait_cmd
        ld a,152                ; Step 2's square
        ld (0xc306),a
        ld hl,0xc300
        jp command
; The arcade's squares, 16x29 here, one every 30 lines: the map's bands
; 1..6 lose 2 lines each to fit in 212 (tools/extract_progress_maps.py).
transition_square:
        dw 0,0,16,182,16,29
        db 0,0x0c,0xff,0xff,0x99,0x99,0,0,0x20


; The arcade's running cadets between the Iron-Man bonus and the map
; (tools/extract_cadets.py, build/step3/cadets.inc): the sergeant, ten cadets
; and, alone behind them, the player, over the barracks, while arcade song
; 27h plays (ARC_CADETS). Time counts arcade frames (60 Hz): one per
; interrupt at 60 Hz, six every five at 50 Hz, so the scene lasts 9.6 s on
; both. RAM: C600h-C617h, two bytes per actor (cycle accumulator and pose),
; unused by every part of the game; C760h time, C762h the 50 Hz remainder,
; C764h the actor's state, C768h the last JIFFY (Step 3's goal variables,
; free by now).
CADET_STATE equ 0xc600
transition_animation:
        di
        call display_off        ; off from the next frame on
        ld hl,transition_anim_palette
        call transition_palette
        ; Background in VRAM at y=512; two ROM banks.
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        ld a,1
        out (0x63),a
        ld a,64
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ld a,65
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ; Atlas at y=768.
        xor a
        out (0x64),a
        out (0x63),a
        ld a,0x80
        out (0x63),a
        ld a,1
        out (0x63),a
        ld a,66
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ; The barracks on both pages; afterwards each frame restores only
        ; the rows of the actors.
        xor a
        ld (0xc0b6),a
.both_pages:
        ld hl,transition_background
        call copy_command
        ld a,(0xc0b6)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld a,(0xc0b6)
        xor 1
        ld (0xc0b6),a
        jr nz,.both_pages
        call wait_cmd
        ld ix,cadet_actors
        ld hl,CADET_STATE
        ld b,CADET_ACTORS
.init:
        ld a,(ix+6)
        ld (hl),a
        inc hl
        ld a,(ix+7)
        ld (hl),a
        inc hl
        ld de,8
        add ix,de
        djnz .init
        ld hl,0
        ld (0xc760),hl
        xor a
        ld (0xc762),a
        ld a,9
        ld (0xc418),a
        ld a,ARC_CADETS
        call psg_arcade         ; enables interrupts
        ld hl,(0xfc9e)
        ld (0xc768),hl
.anim_frame:
        ld hl,cadet_band
        call copy_command
        ld a,(0xc0b6)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld ix,cadet_actors
        ld hl,CADET_STATE
        ld (0xc764),hl
        ld b,CADET_ACTORS
.actor:
        push bc
        call cadet_draw
        ld de,8
        add ix,de
        ld hl,(0xc764)
        inc hl
        inc hl
        ld (0xc764),hl
        pop bc
        djnz .actor
        call wait_cmd
.anim_vblank_end:
        in a,(0x65)
        bit 6,a
        jr nz,.anim_vblank_end
.anim_vblank_start:
        in a,(0x65)
        bit 6,a
        jr z,.anim_vblank_start
        ld a,18
        out (0x64),a
        ld a,(0xc0b6)
        out (0x63),a
        xor 1
        ld (0xc0b6),a
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ; Advance the arcade frames of the interrupts since the last time.
.no_interrupt:
        ld hl,(0xfc9e)
        ld de,(0xc768)
        or a
        sbc hl,de
        ld a,l
        or a
        jr z,.no_interrupt
        ld b,a
        add hl,de
        ld (0xc768),hl
.interrupt:
        ld a,(0xc734)           ; interrupts per second
        cp 60
        ld a,(0xc762)
        jr z,.sixty
        inc a                   ; 50 Hz: six arcade frames every five
.sixty:
        add a,5
.arcade_frame:
        cp 5
        jr c,.frames_done
        sub 5
        push af
        push bc
        call cadet_tick
        pop bc
        pop af
        jr .arcade_frame
.frames_done:
        ld (0xc762),a
        djnz .interrupt
        ld hl,(0xc760)
        ld de,CADET_FRAMES
        or a
        sbc hl,de
        jp c,.anim_frame
        ret

; One arcade frame: the time, and each actor's step in its cycle of poses.
cadet_tick:
        ld hl,(0xc760)
        inc hl
        ld (0xc760),hl
        ld ix,cadet_actors
        ld hl,CADET_STATE
        ld b,CADET_ACTORS
.actor:
        ld a,(ix+5)
        call cadet_kind
        ld a,(de)
        ld c,a                  ; frames of a whole cycle
        ld a,(hl)
        add a,6
        cp c
        jr c,.same_pose
        sub c
        ld (hl),a
        inc hl
        ld a,(hl)
        inc a
        cp 6
        jr c,.pose
        xor a
.pose:
        ld (hl),a
        inc hl
        jr .next
.same_pose:
        ld (hl),a
        inc hl
        inc hl
.next:
        ld de,8
        add ix,de
        djnz .actor
        ret

; A = kind: DE = its record in cadet_kinds. Keeps BC, HL.
cadet_kind:
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        push hl
        ld hl,cadet_kinds
        add hl,de
        ex de,hl
        pop hl
        ret

; Draws actor IX (state at (C764h)) in the hidden page, clipped at the
; screen's edges, once its first frame has come.
cadet_draw:
        ld hl,(0xc760)
        ld e,(ix+0)
        ld d,(ix+1)
        or a
        sbc hl,de
        ret c                   ; not yet
        ld a,(ix+5)
        call cadet_kind
        inc de
        ld a,(de)               ; speed in half pixels per frame
        ld b,h
        ld c,l
        add hl,hl
        cp 3
        jr nz,.halve
        add hl,bc
.halve:
        srl h
        rr l
        ld c,(ix+2)
        ld b,(ix+3)
        add hl,bc               ; x, signed
        ld a,h
        or a
        jr z,.visible           ; 0..255
        inc a
        ret nz                  ; past the right edge, or far left
        ld a,l
        cp 0xe1
        ret c                   ; -32 or less: not yet in
.visible:
        push hl
        ld hl,cadet_runner
        call copy_command
        pop hl
        ld c,0                  ; columns cut on the left
        ld a,h
        or a
        jr z,.left_in
        ld a,l
        neg
        ld c,a
        ld a,32
        sub c
        ld (0xc308),a           ; width
        xor a                   ; from the left edge
        jr .dx
.left_in:
        ld a,l
        cp 225
        jr c,.dx
        neg                     ; 256 - x columns before the right edge
        ld (0xc308),a
        ld a,l
.dx:
        ld (0xc304),a
        ld a,(ix+4)
        ld (0xc306),a           ; its row
        ld a,(0xc0b6)
        ld (0xc307),a           ; of the hidden page
        ld a,(ix+5)
        call cadet_kind
        ld hl,(0xc764)
        inc hl
        ld a,(hl)               ; pose in the cycle
        add a,2
        ld l,a
        ld h,0
        add hl,de
        ld a,(hl)               ; atlas cell
        ld b,a
        and 7
        rrca
        rrca
        rrca                    ; 32 * column
        add a,c
        ld (0xc300),a
        ld a,b
        cp 8
        ld a,0
        jr c,.row
        ld a,48
.row:
        ld (0xc302),a           ; 768 or 816 (high byte in cadet_runner)
        ld hl,0xc300
        jp command

transition_background:
        dw 0,512,0,0,256,212
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
cadet_band:                     ; rows 112-183 hold every actor
        dw 0,512+112,0,112,256,72
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
cadet_runner:
        dw 0,768,0,0,32,48
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
        include "../build/step3/cadets.inc"
transition_bonus_palette: incbin "../build/demo/progress-palette.bin"
transition_map_palette: incbin "../build/demo/map-palette.bin"
transition_anim_palette: incbin "../build/step3/transition-palette.bin"
