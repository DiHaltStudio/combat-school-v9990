        org 0x4000
        db "AB"
        dw boot                 ; power-on: the DiHalt screens, then init
        dw 0,0,0
        jp step6_entry
        jp shoot_start         ; entry after the penalty of Step 1
init:
        di
        ; Map cartridge slot from page 1 into page 2 via BIOS.
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
        jr z,slot_ready
        ; HL points at EXPTBL[primary]. The corresponding SLTTBL
        ; entry gives page 1's subslot in the ENASLT ID's bits 3..2.
        inc hl
        inc hl
        inc hl
        inc hl
        ld a,(hl)
        and 0x0c
        or c
slot_ready:
        ld h,0x80
        call 0x0024
        di
        xor a
        ld (0xf3db),a          ; BIOS CLIKSW: disable the keyboard click
        ld sp,0xf000
        ; Power-on only (boot): DiHalt, the V9990 probe and the logo
        ; (src/boot_logo.asm, bank 27). init is also the way back to the
        ; title after a game.
        ld a,(0xd0f3)
        cp 0xa5
        jr nz,.booted
        xor a
        ld (0xd0f3),a
        ld a,27
        ld (0x7000),a
        call 0x8000
        di
.booted:
        ; New game: the penalty is available again (src/penalty.asm).
        xor a
        ld (0xd0fe),a          ; tests skip the introduction with A5 here
        ld (0xf200),a
        ld (0xf207),a          ; default flag until F1 is sampled at start
        ; New game: the score (C75C..C75E, read by the RANKING after GAME OVER)
        ; and the bonuses of Steps 1 and 2 start at zero.
        ld (0xc75e),a
        ld h,a
        ld l,a
        ld (0xc75c),hl
        ld (0xc414),hl
        ld (0xc440),hl
        ld (0xf206),a
        ld hl,pen_try_code
        ld de,0xf210
        ld bc,pen_try_end-pen_try_code
        ldir
        ; PSG music (src/psg_music.asm): the driver from the end of bank
        ; PSG_ROM_BANK to RAM, hooked to the interrupt; silent on the title.
        ld a,PSG_ROM_BANK
        ld (0x7000),a
        ld hl,PSG_ROM_ADDR
        call psg_install
        di
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
        ld hl,palette
        ld bc,0x3061
        otir
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        out (0x63),a
        ; ASCII16: page 1 holds the code, page 2 streams the bitmap.
        ld a,1
        call image_stream
        ; Eleven course banks, 256 x 112 pixels each, at VRAM y=768 onward.
        ld a,3
        ld (0xc00d),a
        ld a,0x80
        ld (0xc00e),a
        ld a,1
        ld (0xc00f),a
course_upload:
        ld a,(0xc00d)
        ld (0x7000),a
        xor a
        out (0x64),a
        out (0x63),a
        ld a,(0xc00e)
        out (0x63),a
        ld a,(0xc00f)
        out (0x63),a
        ld hl,0x8000
        ld d,56
        call upload_blocks
        ld a,(0xc00e)
        add a,0x40
        ld (0xc00e),a
        jr nc,course_no_carry
        ld a,(0xc00f)
        inc a
        ld (0xc00f),a
course_no_carry:
        ld a,(0xc00d)
        inc a
        ld (0xc00d),a
        cp 14
        jr nz,course_upload
        ld hl,restore_template
        ld de,0xc010
        ld bc,21
        ldir
        ld hl,sprite_template
        ld de,0xc030
        ld bc,21
        ldir
        ; Page y=256 is used as a second display buffer.
        ld a,14
        ld (0x7000),a
        ld hl,0x8000
        xor a
        ld (0xc002),a
sprite_frame:
        ld a,(0xc002)
        ld e,a
        ld d,0
        ld b,48
sprite_upload:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,1
        out (0x63),a
        ld bc,0x1060
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,sprite_no_carry
        inc d
sprite_no_carry:
        pop bc
        djnz sprite_upload
        ld a,(0xc002)
        add a,16
        ld (0xc002),a
        cp 64
        jr nz,sprite_frame
        ; Jump frame: 48x48, with native arcade pixel dimensions.
        ld de,64
        ld b,48
jump_upload:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,1
        out (0x63),a
        ld bc,0x1860
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,jump_no_carry
        inc d
jump_no_carry:
        pop bc
        djnz jump_upload
        xor a
        ld (0xc002),a
fall_frame:
        ld a,(0xc002)
        ld e,a
        ld d,0x2c
        ld b,48
fall_upload:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,1
        out (0x63),a
        ld bc,0x1860
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,fall_no_carry
        inc d
fall_no_carry:
        pop bc
        djnz fall_upload
        ld a,(0xc002)
        add a,24
        ld (0xc002),a
        cp 96
        jr nz,fall_frame
        ; Climbing frames at x=0,32 and y=664.
        xor a
        ld (0xc002),a
climb_frame:
        ld a,(0xc002)
        ld e,a
        ld d,0x4c
        ld b,48
climb_upload:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,1
        out (0x63),a
        ld bc,0x1060
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,climb_no_carry
        inc d
climb_no_carry:
        pop bc
        djnz climb_upload
        ld a,(0xc002)
        add a,16
        ld (0xc002),a
        cp 80
        jr nz,climb_frame
        ; Six 48x56 hanging poses in bank 15, VRAM y=2304/2368.
        ld a,15
        ld (0x7000),a
        ld hl,0x8000
        xor a
        ld (0xc002),a
hang_frame:
        ld a,(0xc002)
        cp 5
        jr z,hang_last
        ld e,a
        add a,a
        add a,e
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0x80
        jr hang_setup
hang_last:
        ld de,0xa000
hang_setup:
        ld b,56
hang_upload:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,4
        out (0x63),a
        ld bc,0x1860
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,hang_no_carry
        inc d
hang_no_carry:
        pop bc
        djnz hang_upload
        ld a,(0xc002)
        inc a
        ld (0xc002),a
        cp 6
        jr nz,hang_frame
        ; CPU atlas: four running poses, jump and resting pose.
        ld a,16
        ld (0x7000),a
        ld hl,0x8000
        xor a
        ld (0xc002),a
cpu_upload_frame:
        ld a,(0xc002)
        ld e,a
        ld d,0xc0
        ld b,48
cpu_upload_row:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,4
        out (0x63),a
        ld a,(0xc002)
        cp 64
        ld bc,0x1060
        jr c,cpu_upload_bytes
        cp 88
        jr z,cpu_upload_bytes
        ld bc,0x1860
cpu_upload_bytes:
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,cpu_upload_no_carry
        inc d
cpu_upload_no_carry:
        pop bc
        djnz cpu_upload_row
        ld a,(0xc002)
        cp 88
        jr z,cpu_upload_done
        cp 64
        jr nz,cpu_upload_advance
        ld a,88
        jr cpu_upload_store
cpu_upload_advance:
        add a,16
cpu_upload_store:
        ld (0xc002),a
        jr cpu_upload_frame
cpu_upload_done:
        ; Timer, result glyphs and POWER label, bank 17, x=0..239 at y=2500;
        ; rows 16-31 (y=2516) hold PLAYER 1(NICK) and YOU MADE IT, rows 32-41
        ; (y=2532) YOU BLEW IT.
        ld a,17
        ld (0x7000),a
        ld hl,0x8000
        ld de,0xe200
        ld b,42
ui_upload_row:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,4
        out (0x63),a
        ld bc,0x7860
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,ui_upload_next
        inc d
ui_upload_next:
        pop bc
        djnz ui_upload_row
        ; CPU hanging atlas in bank 18, VRAM y=2560/2624.
        ld a,18
        ld (0x7000),a
        ld hl,0x8000
        xor a
        ld (0xc002),a
cpu_hang_frame:
        ld a,(0xc002)
        cp 5
        jr z,cpu_hang_last
        ld e,a
        add a,a
        add a,e
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        jr cpu_hang_setup
cpu_hang_last:
        ld de,0x2000
cpu_hang_setup:
        ld b,56
cpu_hang_row:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,5
        out (0x63),a
        ld bc,0x1860
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,cpu_hang_next
        inc d
cpu_hang_next:
        pop bc
        djnz cpu_hang_row
        ld a,(0xc002)
        inc a
        ld (0xc002),a
        cp 6
        jr nz,cpu_hang_frame
        ; Six 48x64 instructor poses, ROM bank 57: 0-3 at VRAM y=2688,
        ; 4-5 (goal gestures) at y=2752, columns of 48 pixels.
        ld a,57
        ld (0x7000),a
        ld hl,0x8000
        xor a
        ld (0xc002),a
instructor_upload_frame:
        ld a,(0xc002)
        ld d,0x40
        cp 4
        jr c,instructor_upload_column
        sub 4
        ld d,0x60
instructor_upload_column:
        ld e,a
        add a,a
        add a,e
        add a,a
        add a,a
        add a,a
        ld e,a
        ld b,64
instructor_upload_row:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,5
        out (0x63),a
        ld bc,0x1860
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,instructor_upload_next
        inc d
instructor_upload_next:
        pop bc
        djnz instructor_upload_row
        ld a,(0xc002)
        inc a
        ld (0xc002),a
        cp 6
        jr nz,instructor_upload_frame
        ; Seated landing poses, player then CPU, at VRAM y=2816.
        ld a,94
        ld (0x7000),a
        ld hl,0x8000
        xor a
        ld (0xc002),a
seated_upload_frame:
        ld a,(0xc002)
        or a
        ld e,0
        jr z,seated_upload_setup
        ld e,24
seated_upload_setup:
        ld d,0x80
        ld b,48
seated_upload_row:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,5
        out (0x63),a
        ld bc,0x1860
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,seated_upload_next
        inc d
seated_upload_next:
        pop bc
        djnz seated_upload_row
        ld a,(0xc002)
        inc a
        ld (0xc002),a
        cp 2
        jr nz,seated_upload_frame
        ; Player goal poses follow in the same bank: four 32x64 cells at
        ; VRAM x=96,128,160,192, y=2816 (bent, standing, half and raised arm).
        xor a
        ld (0xc002),a
goal_upload_frame:
        ld a,(0xc002)
        add a,a
        add a,a
        add a,a
        add a,a
        add a,48
        ld e,a
        ld d,0x80
        ld b,64
goal_upload_row:
        push bc
        xor a
        out (0x64),a
        ld a,e
        out (0x63),a
        ld a,d
        out (0x63),a
        ld a,5
        out (0x63),a
        ld bc,0x1060
        otir
        ld a,e
        add a,128
        ld e,a
        jr nc,goal_upload_next
        inc d
goal_upload_next:
        pop bc
        djnz goal_upload_row
        ld a,(0xc002)
        inc a
        ld (0xc002),a
        cp 4
        jr nz,goal_upload_frame
        call show_intro
        xor a
        ld (0xc001),a
        ld (0xc003),a
        ld (0xc004),a
        ld (0xc006),a
        ld (0xc007),a
        ld (0xc008),a
        ld (0xc009),a
        ld (0xc00a),a
        ld (0xc00b),a
        ld (0xc00c),a
        ld (0xc082),a
        ld (0xc086),a
        ld (0xc087),a
        ld (0xc088),a
        ld (0xc089),a
        ld (0xc08a),a
        ld (0xc08e),a
        ld (0xc08f),a
        ld (0xc090),a
        ld (0xc091),a
        ld (0xc094),a
        ld (0xc095),a
        ld (0xc096),a
        ld (0xc097),a
        ld (0xc09a),a
        ld (0xc0c4),a
        ld (0xc0c5),a
        ld (0xc0c6),a
        ld (0xc0d1),a
        ld (0xc0d4),a
        ld (0xc0d5),a
        ld (0xc0d9),a
        ld (0xc0dc),a
        ld (0xc0b8),a
        ld (0xc0fc),a
        ld (0xc0fd),a
        ld (0xc0fe),a
        ld (0xc0ff),a
        ld (0xc412),a
        ld (0xc418),a
        ld a,1
        ld (0xc0ba),a
        ld a,1
        ld (0xc0d8),a
        ; The arcade starts the first event with 35 seconds.
        ld a,35
        ld (0xc0d0),a
        ld a,64
        ld (0xc092),a
        ld a,159
        ld (0xc093),a
        ld a,55
        ld (0xc005),a
        ld a,64
        ld (0xc000),a
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ; BIOS identifies the machine's default interrupt frequency.
        ld a,(0x002b)
        bit 7,a
        ld a,60
        jr z,.clock_rate_ready
        ld a,50
.clock_rate_ready:
        ld (0xc0dd),a
        ld hl,(0xfc9e)
        ld (0xc0da),hl
        ld a,2                  ; obstacle course music
        call psg_play
        ei
loop:
        ; The starter gives the signal before either runner or timer moves.
        ld a,(0xc0ba)
        or a
        jr z,.race_started
        ld hl,(0xfc9e)
        ld de,(0xc0da)
        or a
        sbc hl,de
        ld a,h
        or a
        jr nz,.start_race
        ld a,(0xc0dd)
        cp l
        jp nc,.draw
.start_race:
        xor a
        ld (0xc0ba),a
        ld hl,(0xfc9e)
        ld (0xc0da),hl
.race_started:
        ld a,(0xc086)
        or a
        jr z,.normal_tick
        dec a
        ld (0xc086),a
        jr nz,.fall_active
        xor a
        ld (0xc0ff),a
        jr .normal_tick
.fall_active:
        ld a,(0xc0ff)
        cp 1
        jr nz,.fall_height_ready
        ld a,(0xc005)
        cp 53
        jr nc,.fall_land
        add a,2
        ld (0xc005),a
        jr .fall_height_ready
.fall_land:
        ld a,55
        ld (0xc005),a
        ld a,2
        ld (0xc0ff),a
.fall_height_ready:
        call knockback_tick
        jp .draw
.normal_tick:
        ld a,(0xc0d9)
        or a
        jr z,.check_climb
        ld a,(0xc0d5)
        or a
        jr nz,.goal_stop
        ld a,(0xc0d9)
        cp 3
        jr z,.failed_result
        ; Past the finish line: keep running by himself to the stop point
        ; beside the instructor (camera end, C0D5).
        ld a,(0xc008)
        cp 24
        jr nc,.check_climb
        ld a,24
        ld (0xc008),a
        jr .check_climb
.goal_stop:
        ; The camera has stopped, but a jump across the line still needs
        ; to land before the panting pose and the result timer begin.
        ld a,(0xc005)
        cp 52
        jr nc,.goal_grounded
        add a,3
        ld (0xc005),a
        jp .draw
.goal_grounded:
        ld a,55
        ld (0xc005),a
        xor a
        ld (0xc003),a
        call progress_tick
        jp .draw
.failed_result:
        ; Lost by a short distance: the penalty, once per game.
        call step1_penalty
        jp c,.draw
        ; A fresh press of the run button starts a new race.
        xor a
        call 0x00d8
        or a
        jr nz,.restart_pressed
        ld a,1
        call 0x00d8
        or a
        jr nz,.restart_pressed
        ld a,1
        ld (0xc0dc),a
        jp .draw
.restart_pressed:
        ld a,(0xc0dc)
        or a
        jp nz,init
        jp .draw
.check_climb:
        ld a,(0xc087)
        or a
        jr z,.not_climbing
        call climb_tick
        jp .draw
.not_climbing:
        ld a,(0xc0d9)
        or a
        jr nz,.advance_jump    ; finish the current jump during the run-out
        ; Salto: M (fila 4, bit 2) o botón 2 del joystick.
        ld a,4
        call 0x0141
        bit 2,a
        ld a,0xff
        jr z,.trigger
        ld a,2
        call 0x00d8
.trigger:
        ld b,a
        ld a,(0xc004)
        ld c,a
        ld a,b
        ld (0xc004),a
        or a
        jr z,.advance_jump
        ld a,c
        or a
        jr nz,.advance_jump
        ld a,(0xc003)
        or a
        jr nz,.advance_jump
        ld a,1
        ld (0xc003),a
.advance_jump:
        ld a,(0xc00a)
        or a
        jr z,.jump_normal
        ld a,24
        ld (0xc005),a
        jr .move
.jump_normal:
        ld a,(0xc003)
        or a
        jr z,.ground
        ld e,a
        ld d,0
        ld hl,jump_heights-1
        add hl,de
        ld a,55
        sub (hl)
        ld (0xc005),a
        ld a,e
        add a,2
        cp 33
        jr c,.save_jump
        xor a
.save_jump:
        ld (0xc003),a
        call try_grab
        jr .move
.ground:
        ld a,55
        ld (0xc005),a
.move:
        call clamp_wall_height
        ld a,(0xc087)
        or a
        jp nz,.draw
        ; A standing jump beside a low wall can initiate an automatic vault.
        ld a,(0xc003)
        or a
        jr z,.check_auto
        call can_advance
.check_auto:
        ; After a successful vault, carry the runner beyond the wall automatically.
        ld a,(0xc088)
        or a
        jr z,.manual_run
        call can_advance
        ld a,(0xc082)
        or a
        jr nz,.auto_step
        xor a
        ld (0xc088),a
        jr .manual_run
.auto_step:
        ld a,(0xc000)
        cp 100
        jr nc,.auto_scroll
        add a,6
        ld (0xc000),a
        jp .animate
.auto_scroll:
        ; Ease the runner back towards the usual screen position while the
        ; camera catches up. World movement remains six pixels per tick.
        ld a,(0xc000)
        cp 102
        ld b,6
        jr c,.auto_scroll_step
        sub 2
        ld (0xc000),a
        ld b,8
.auto_scroll_step:
        ld a,(0xc006)
        add a,b
        ld (0xc006),a
        jr nc,.auto_done
        ld a,(0xc00c)
        inc a
        ld (0xc00c),a
.auto_done:
        jp .animate
.manual_run:
        ; Impulso: flanco de espacio o botón 1 del joystick.
        xor a
        call 0x00d8
        or a
        jr nz,.run_input
        ld a,1
        call 0x00d8
.run_input:
        ld b,a
        ld a,(0xc009)
        ld c,a
        ld a,b
        ld (0xc009),a
        or a
        jr z,.decay
        ld a,c
        or a
        jr nz,.decay
        ld a,(0xc008)
        add a,12
        cp 49
        jr c,.store_energy
        ld a,48
.store_energy:
        ld (0xc008),a
.decay:
        ; La energía baja gradualmente si no se vuelve a pulsar.
        ld a,(0xc008)
        or a
        jr z,.speed
        dec a
        ld (0xc008),a
.speed:
        ld a,(0xc008)
        or a
        jp z,.draw
        ; Velocidad provisional: energía / 48 pasos de dos píxeles por cuadro.
        ld b,a
        ld a,(0xc00b)
        add a,b
        ld (0xc00b),a
        cp 48
        jp c,.animate
        sub 48
        ld (0xc00b),a
        call can_advance
        jr nc,.advance_ok
        ld a,(0xc087)
        or a
        jp nz,.draw
        ld a,(0xc08f)
        cp 2
        jp z,.draw
        or a
        jp nz,.animate
        ; Low speed stops at the wall; faster impacts fall or bounce back.
        ld a,(0xc008)
        cp 16
        jr nc,.impact_fall
        xor a
        ld (0xc008),a
        ld (0xc00b),a
        jp .draw
.impact_fall:
        cp 32
        jr nc,.impact_back
        ; At a low barrier a moderate collision falls forward. Higher
        ; barriers recoil; speed can still force recoil at a low barrier.
        ld a,(0xc08b)
        cp 39
        ld a,0
        jr z,.impact_type
.impact_back:
        ld a,1
.impact_type:
        ld (0xc08a),a
        or a
        ld a,0
        jr z,.impact_nobounce
        ld a,12
.impact_nobounce:
        ld (0xc089),a
        ld a,75
        ld (0xc086),a
        xor a
        ld (0xc008),a
        ld (0xc00b),a
        ld (0xc003),a
        ld (0xc082),a
        ld a,55
        ld (0xc005),a
        jp .draw
.advance_ok:
        call stride_points
        ld a,(0xc000)
        cp 100
        jr nc,.scroll
        add a,4
        ld (0xc000),a
        jr .animate
.scroll:
        ld a,1
        ld (0xc007),a
        ; Clamp the provisional course at 2488 pixels from its start.
        ld a,(0xc00c)
        cp 9
        jr c,.advance_scroll
        ld a,(0xc006)
        cp 180
        jr c,.advance_scroll
        ld a,184
        ld (0xc006),a
        ld a,1
        ld (0xc0d5),a
        jr .animate
.advance_scroll:
        ld a,(0xc006)
        add a,4
        ld (0xc006),a
        jr nc,.animate
        ld a,(0xc00c)
        inc a
        ld (0xc00c),a
.animate:
        call check_hang_end
        ld a,(0xc001)
        add a,2
        cp 30
        jr c,.phase
        xor a
.phase: ld (0xc001),a
        cp 6
        ld a,32
        jr c,.source
        ld a,(0xc001)
        cp 12
        ld a,64
        jr c,.source
        ld a,(0xc001)
        cp 18
        ld a,0
        jr c,.source
        ld a,(0xc001)
        cp 24
        ld a,96
        jr c,.source
        ld a,64
        jr .source
.draw:  xor a
.source:
        ld b,a
        xor a
        ld (0xc08d),a
        ld a,(0xc00a)
        or a
        ld a,b
        jr z,.source_ready
        ld a,(0xc001)
        cp 5
        ld a,0
        jr c,.source_ready
        ld a,(0xc001)
        cp 10
        ld a,48
        jr c,.source_ready
        ld a,(0xc001)
        cp 15
        ld a,96
        jr c,.source_ready
        ld a,(0xc001)
        cp 20
        ld a,144
        jr c,.source_ready
        ld a,(0xc001)
        cp 25
        ld a,192
        jr c,.source_ready
        ld a,64
        ld (0xc08d),a
        xor a
.source_ready:
        ld b,a
        ld a,(0xc087)
        or a
        ld a,b
        jr z,.not_climb_source
        ; The support countdown uses the actual hand-on-wall poses.
        ld a,(0xc08e)
        or a
        jr z,.ascent_pose
        cp 4
        ld a,64
        jr nc,.selected_source
        ld a,(0xc08e)
        cp 2
        ld a,96
        jr nc,.selected_source
        ; Push off before returning to the normal jump pose.
        ld a,128
        jr .selected_source
.ascent_pose:
        ld a,(0xc085)
        ld b,a
        ld a,(0xc005)
        sub b
        cp 8
        ld a,0
        jr nc,.selected_source
        ld a,(0xc005)
        sub b
        cp 4
        ld a,32
        jr nc,.selected_source
        ; Near the top, reach for the wall before placing the hand on it.
        ld a,64
        jr .selected_source
.not_climb_source:
        ld b,a
        ld a,(0xc0ff)
        or a
        ld a,0
        jr nz,.selected_source
        ld a,b
        ld b,a
        ld a,(0xc086)
        or a
        ld a,b
        jr z,.selected_source
        ld a,(0xc086)
        cp 60
        ld a,0
        jr nc,.fall_type
        ld a,48
.fall_type:
        ld b,a
        ld a,(0xc08a)
        or a
        ld a,b
        jr z,.selected_source
        add a,96
.selected_source:
        push af
        call scroll_track
        pop af
        ld b,a
        ld a,(0xc087)
        or a
        ld a,b
        jr nz,.frame_selected
        ld a,(0xc086)
        or a
        ld a,b
        jr nz,.frame_selected
        ld a,(0xc00a)
        or a
        ld a,b
        jr nz,.frame_selected
        ld a,(0xc005)
        cp 55
        ld a,b
        jr z,.frame_selected
        ld a,128
.frame_selected:
        ld (0xc030),a
        ld a,(0xc00a)
        or a
        jr z,.source_non_hang
        ld a,(0xc08d)
        ld (0xc032),a
        ld a,9
        ld (0xc033),a
        jr .select_width
.source_non_hang:
        ld a,(0xc0ff)
        or a
        jr z,.ordinary_source_y
        xor a
        ld (0xc032),a
        ld a,11
        ld (0xc033),a
        jr .select_width
.ordinary_source_y:
        ld a,2
        ld (0xc033),a
        ld a,(0xc087)
        or a
        ld a,152
        jr nz,.normal_source_y
        ld a,(0xc086)
        or a
        ld a,0
        jr z,.normal_source_y
        ld a,88
.normal_source_y:
        ld (0xc032),a
.select_width:
        ld a,(0xc087)
        or a
        ld a,32
        jr nz,.frame_width
        ld a,(0xc030)
        cp 128
        ld a,32
        jr nz,.check_fall_width
        ld a,48
.check_fall_width:
        ld b,a
        ld a,(0xc00a)
        or a
        ld a,48
        jr nz,.frame_width
        ld a,(0xc086)
        or a
        ld a,b
        jr z,.frame_width
        ld a,48
.frame_width:
        ld (0xc038),a
        ld a,(0xc00a)
        or a
        ld a,48
        jr z,.frame_height
        ld a,56
.frame_height:
        ld (0xc03a),a
        ld a,(0xc005)
        ld b,a
        ld a,(0xc087)
        or a
        ld a,b
        jr z,.frame_y
        ld a,(0xc030)
        or a
        jr nz,.check_second_hand_y
        ; The hanging pose is fixed by its raised hand, not by the feet.
        ld a,(0xc085)
        add a,39
        jr .frame_y
.check_second_hand_y:
        cp 32
        jr nz,.check_crouch_hand_y
        ; Transitional pull-up pose: its lower hand is 30 pixels down.
        ld a,(0xc085)
        add a,13
        jr .frame_y
.check_crouch_hand_y:
        cp 64
        jr nz,.check_push_hand_y
        ld a,(0xc085)
        jr .frame_y
.check_push_hand_y:
        cp 96
        ld a,b
        jr nz,.frame_y
        ; In this pose the hand is five pixels lower in its frame.
        sub 5
.frame_y:
        ld (0xc036),a
        ld a,(0xc0d8)
        ld (0xc037),a
        ld a,(0xc000)
        ld b,a
        ld a,(0xc00a)
        or a
        jr nz,.wide_frame_x
        ld a,(0xc086)
        or a
        jr nz,.wide_frame_x
        ld a,(0xc087)
        or a
        jr z,.not_support_x
        ld a,(0xc030)
        or a
        jr z,.hand_x_grab
        cp 32
        jr z,.hand_x_pull
        cp 64
        jr z,.hand_x_64
        cp 96
        jr nz,.push_off_x
        ; The hand advances across the top as the body passes over it.
        ld c,4                 ; hand offset 12, less eight pixels of progress
        jr .anchor_hand
.hand_x_grab:
        ld c,30
        jr .anchor_hand
.hand_x_pull:
        ld c,25
        jr .anchor_hand
.hand_x_64:
        ld c,17                ; hand offset 21, less four pixels of progress
.anchor_hand:
        ; Place the hand on the top without moving a runner who is already
        ; over the wall back to its leading edge.
        ld a,(0xc083)
        sub 53
        ld b,a
        ld a,(0xc006)
        ld d,a
        ld a,b
        sub d
        sub c
        ld b,a
        ld a,(0xc000)
        sub 8
        cp b
        ld a,b
        jr nc,.minimum_hand_x
        jr .frame_x
.minimum_hand_x:
        ld a,(0xc000)
        sub 8
        jr .frame_x
.push_off_x:
        cp 128
        ld a,b
        jr nz,.frame_x
        ; Continue the supported motion into the push-off pose.
        ld a,(0xc083)
        sub 63
        ld c,a
        ld a,(0xc006)
        ld d,a
        ld a,c
        sub d
        cp b
        jr nc,.frame_x
        ld a,b
        jr .frame_x
.not_support_x:
        ld a,(0xc030)
        cp 128
        ld a,b
        jr nz,.frame_x
.wide_frame_x:
        ld a,b
        sub 8
.frame_x:
        ld (0xc034),a
        call goal_pose
        ld hl,0xc030
        call command
        call cpu_step
        call draw_other_runners
        call bars_overtake
        call instructor_step
        call ui_step
        call wait_cmd
        ; Save the finished page's own state before publishing it.
        ld a,(0xc0d8)
        or a
        ld de,0xc100
        jr z,.save_page_state
        ld de,0xc200
.save_page_state:
        ld hl,0xc000
        ld bc,256
        ldir
        ; Publish the fully composed page at a V9990 vertical boundary.
.flip_wait0:
        di                      ; no interrupt between the blank and the page (music)
        in a,(0x65)
        bit 6,a
        jr nz,.flip_wait0
.flip_wait1:
        in a,(0x65)
        bit 6,a
        jr z,.flip_wait1
        ld a,17
        out (0x64),a
        xor a
        out (0x63),a
        ld a,(0xc0d8)
        out (0x63),a
        ei
        xor 1
        ld (0xc0d8),a
        jp loop

 ; Recoil is limited so camera and player never wrap behind the course start.
knockback_tick:
        ld a,(0xc089)
        or a
        ret z
        dec a
        ld (0xc089),a
        ld a,(0xc006)
        or a
        jr nz,.back
        ld a,(0xc00c)
        or a
        jr z,.back_actor
        dec a
        ld (0xc00c),a
        ld a,0
.back:  sub 2
        ld (0xc006),a
        ret
.back_actor:
        ld a,(0xc000)
        cp 66
        ret c
        sub 2
        ld (0xc000),a
        ret

; Arcade: 10 points per stride of the run (also hanging from the bars),
; about 150 per second at full speed. Here, 10 every 8 pixels of advance:
; bit 2 of camera + actor alternates on each 4-pixel step. None past the line.
stride_points:
        ld a,(0xc0d9)
        or a
        ret nz
        ld a,(0xc006)
        ld b,a
        ld a,(0xc000)
        add a,b
        and 4
        ret z
        ld de,10
; DE = points added to the game score C75C..C75E (24 bits, little endian).
add_score:
        ld hl,(0xc75c)
        add hl,de
        ld (0xc75c),hl
        ret nc
        ld hl,0xc75e
        inc (hl)
        ret

; Compute player world position from camera and actor x (centre).
world_centre:
        ld a,(0xc006)
        ld l,a
        ld a,(0xc00c)
        ld h,a
        ld a,(0xc000)
        ld e,a
        ld d,0
        add hl,de
        ld de,16
        add hl,de
        ret

; Enter the bar state only while a jump reaches its height and range.
try_grab:
        ld a,(0xc005)
        cp 41
        ret nc
        call world_centre
        ld de,2032
        or a
        sbc hl,de
        ret c
        ld de,398
        or a
        sbc hl,de
        ret nc
        ld a,1
        ld (0xc00a),a
        xor a
        ld (0xc003),a
        ld a,24
        ld (0xc005),a
        ret

; At the right end of the bars, begin descending.
check_hang_end:
        ld a,(0xc00a)
        or a
        ret z
        call world_centre
        ld de,2430
        or a
        sbc hl,de
        ret c
        xor a
        ld (0xc00a),a
        ld a,21
        ld (0xc003),a
        ret

; On descent, touching the top initiates a short hand-supported vault.
; A jump that clears the far edge before descending never enters this state.
clamp_wall_height:
        ld a,(0xc082)
        or a
        ret z
        ld a,(0xc085)
        ld b,a
        ld a,(0xc005)
        cp b
        ret c
        ld a,(0xc003)
        or a
        jr nz,.jump_phase
        ld a,(0xc0c6)
        or a
        jr nz,.hold_height
        jr .land_on_wall
.jump_phase:
        cp 17
        jr c,.hold_height
.land_on_wall:
        ld a,b
        ld (0xc005),a
        xor a
        ld (0xc003),a
        ld a,1
        ld (0xc087),a
        ld a,6
        ld (0xc08e),a
        ret
.hold_height:
        ld a,b
        ld (0xc005),a
        ret

; Animated assisted ascent for high walls; controls resume on top.
climb_tick:
        ld a,(0xc08e)
        or a
        jr z,.climb_up
        dec a
        ld (0xc08e),a
        ret nz
        jr .done
.climb_up:
        ld a,(0xc005)
        ld b,a
        ld a,(0xc085)
        cp b
        jr nc,.start_support
        ld a,b
        ; Keep the grip visible while the runner pulls up the high wall.
        sub 1
        cp b
        jr c,.check_top
        xor a
.check_top:
        ld b,a
        ld a,(0xc085)
        cp b
        jr nc,.store
        ld a,b
.store: ld (0xc005),a
        ret
.start_support:
        ld a,6
        ld (0xc08e),a
        ret
.done:  ld a,(0xc083)
        sub 55
        ld b,a
        ld a,(0xc006)
        ld c,a
        ld a,b
        sub c
        ld b,a
        ld a,(0xc000)
        cp b
        jr nc,.no_exit_advance
        ld a,b
        ld (0xc000),a
.no_exit_advance:
        xor a
        ld (0xc087),a
        ld (0xc003),a
        ld a,1
        ld (0xc0c6),a
        ld (0xc082),a
        ld (0xc088),a
        ret

; Check the leading edge against approximate wall bounds and top heights.
; Carry means the next horizontal step would hit a wall.
can_advance:
        xor a
        ld (0xc08f),a
        ld a,(0xc00a)
        or a
        ret nz
        ; As in the arcade, the front post of the bars stops a runner on the
        ; ground: only a jump that grabs the bars (try_grab) gets past it.
        ; C08F=2: standing pose, no fall or recoil; the energy still rises.
        ld a,(0xc003)
        or a
        jr nz,.not_bars
        call world_centre
        ld de,2032
        or a
        sbc hl,de
        jr c,.not_bars
        ld de,398
        sbc hl,de
        jr nc,.not_bars
        ld a,2
        ld (0xc08f),a
        scf
        ret
.not_bars:
        call world_centre
        ld de,12
        add hl,de
        ld (0xc080),hl
        ld a,(0xc082)
        or a
        jr z,.find_wall
        ld de,(0xc083)
        or a
        sbc hl,de
        jp c,.clear
        xor a
        ld (0xc082),a
        ld (0xc088),a
.find_wall:
        ld ix,wall_table
.wall:
        ld e,(ix+0)
        ld d,(ix+1)
        ld a,d
        cp 0xff
        jp z,.clear
        ld hl,(0xc080)
        or a
        sbc hl,de
        jp c,.next
        ld e,(ix+2)
        ld d,(ix+3)
        ld hl,(0xc080)
        or a
        sbc hl,de
        jr nc,.next
        ld a,(0xc005)
        cp (ix+4)
        jr c,.clear_wall
        jr z,.clear_wall
        ld a,(ix+4)
        cp 39
        jr nc,.impact
        ld a,(0xc003)
        or a
        jr z,.impact
        cp 17
        jr nc,.descending_contact
        ; During ascent stay in front of the high wall, without entering it.
        ld a,(0xc005)
        cp 41
        jr nc,.impact
        ld a,1
        ld (0xc08f),a
        jr .impact
.descending_contact:
        cp 33
        jr nc,.impact
        ld a,(0xc005)
        cp 41
        jr nc,.impact
        ld (0xc083),de
        ld hl,20
        add hl,de
        ld (0xc083),hl
        ld a,(ix+4)
        ld (0xc085),a
        ld a,1
        ld (0xc087),a
.impact:
        ld a,(ix+4)
        ld (0xc08b),a
        scf
        ret
.clear_wall:
        ; Arcade: a wall cleared by a jump, without the hands, scores 500.
        push de
        ld de,500
        call add_score
        pop de
        xor a
        ld (0xc0c6),a
        ld hl,20
        add hl,de
        ld (0xc083),hl
        ld a,(ix+4)
        ld (0xc085),a
        ld a,1
        ld (0xc082),a
        ld (0xc088),a
        or a
        ret
.next:  ld de,5
        add ix,de
        jp .wall
.clear: or a
        ret
wall_table:
        dw 317,350
        db 39
        dw 605,638
        db 24
        dw 763,796
        db 39
        dw 956,989
        db 39
        dw 1114,1147
        db 8
        dw 1276,1309
        db 24
        dw 1470,1503
        db 8
        dw 1630,1665
        db 24
        dw 1818,1853
        db 8
        dw 0xffff,0
        db 0

; Draw each actor in the other camera. Actor command blocks contain the exact
; current source frame; clipping preserves partially visible actors at edges.
draw_other_runners:
        ld hl,0xc0a0
        ld de,0xc300
        ld bc,21
        ldir
        ld a,(0xc090)
        ld l,a
        ld a,(0xc091)
        ld h,a
        ld a,(0xc0a4)
        ld e,a
        ld d,0
        add hl,de
        ld a,(0xc006)
        ld e,a
        ld a,(0xc00c)
        ld d,a
        or a
        sbc hl,de
        push hl
        ld a,(0xc0a3)
        cp 10
        ld b,104
        jr nz,.cpu_y
        ld b,112
.cpu_y:
        ld a,(0xc0a6)
        sub b
        ld (0xc306),a
        pop hl
        call draw_clipped_runner
        ld hl,0xc030
        ld de,0xc300
        ld bc,21
        ldir
        ld a,(0xc006)
        ld l,a
        ld a,(0xc00c)
        ld h,a
        ld a,(0xc034)
        ld e,a
        ld d,0
        add hl,de
        ld a,(0xc090)
        ld e,a
        ld a,(0xc091)
        ld d,a
        or a
        sbc hl,de
        push hl
        ld a,(0xc033)
        cp 9
        ld b,104
        jr nz,.player_y
        ld b,112
.player_y:
        ld a,(0xc036)
        add a,b
        ld (0xc306),a
        pop hl
        jp draw_clipped_runner

; HL = signed horizontal position relative to the destination viewport.
draw_clipped_runner:
        ld a,h
        or a
        jr z,.right_edge
        cp 0xff
        ret nz
        ld a,l
        or a
        ret z                    ; -256 is completely outside the viewport
        cpl
        inc a
        ld b,a
        ld a,(0xc308)
        cp b
        ret c
        ret z
        sub b
        ld (0xc308),a
        ld a,(0xc300)
        add a,b
        ld (0xc300),a
        jr nc,.left_source_ok
        ld a,(0xc301)
        inc a
        ld (0xc301),a
.left_source_ok:
        xor a
        ld (0xc304),a
        ld (0xc305),a
        ld hl,0xc300
        jp command
.right_edge:
        ld a,l
        ld (0xc304),a
        xor a
        ld (0xc305),a
        ld a,(0xc308)
        add a,l
        jr nc,.draw
        xor a
        sub l
        ld (0xc308),a
.draw:
        ld hl,0xc300
        jp command

; Detect an actual pass while both runners hang from the bars. The runner
; being passed falls; a cooldown prevents repeated hits during recovery.
bars_overtake:
        ld a,(0xc0fd)
        or a
        jr z,.check_bars
        dec a
        ld (0xc0fd),a
        xor a
        ld (0xc0fc),a
        ret
.check_bars:
        ld a,(0xc00a)
        or a
        jp z,.reset
        ld a,(0xc0c4)
        or a
        jp z,.reset
        ; Relative world position: player minus CPU.
        ld a,(0xc006)
        ld l,a
        ld a,(0xc00c)
        ld h,a
        ld a,(0xc000)
        ld e,a
        ld d,0
        add hl,de
        push hl
        ld a,(0xc090)
        ld l,a
        ld a,(0xc091)
        ld h,a
        ld a,(0xc092)
        ld e,a
        ld d,0
        add hl,de
        ex de,hl
        pop hl
        or a
        sbc hl,de
        ld a,h
        or l
        ret z
        bit 7,h
        ld b,1                  ; player behind
        jr nz,.side_ready
        inc b                   ; player ahead
.side_ready:
        ld a,(0xc0fc)
        or a
        jr z,.save_side
        cp b
        jr z,.save_side
        ; Ignore teleports and unrelated large position changes.
        ld a,h
        or a
        jr z,.positive_distance
        cp 0xff
        jr nz,.save_side
        ld a,l
        cp 244                  ; at most 12 pixels behind
        jr c,.save_side
        jr .passed
.positive_distance:
        ld a,l
        cp 13
        jr nc,.save_side
.passed:
        ld a,80
        ld (0xc0fd),a
        xor a
        ld (0xc0fc),a
        ld a,b
        cp 2
        jr z,.cpu_falls
        ; CPU overtook the player.
        xor a
        ld (0xc00a),a
        ld (0xc003),a
        ld (0xc008),a
        ld (0xc089),a
        ld (0xc08a),a
        ld a,40
        ld (0xc086),a
        ld a,1
        ld (0xc0ff),a
        ret
.cpu_falls:
        xor a
        ld (0xc097),a          ; a fall loses the accumulated power
        ld (0xc0c4),a
        ld (0xc094),a
        ld a,136
        ld (0xc093),a
        ld a,45
        ld (0xc0fe),a
        ret
.save_side:
        ld a,b
        ld (0xc0fc),a
        ret
.reset:
        xor a
        ld (0xc0fc),a
        ret

; CPU prototype: independent camera and automatic progress. Both runners use
; the same reconstructed course; no MAME logic has yet been translated.
cpu_step:
        ld a,(0xc0ba)
        or a
        jp nz,cpu_draw_only
        ld a,(0xc0d9)
        or a
        jr z,.racing
        ; The race is decided (the player crossed the line first, or the
        ; time ran out): the CPU stops where it is, on the ground, tired
        ; (cpu_draw_only: the rest pose of the goal), not in a running frame.
        xor a
        ld (0xc0fe),a
        ld (0xc094),a
        ld (0xc0c4),a
        ld a,159
        ld (0xc093),a
        jp cpu_draw_only
.racing:
        ld a,(0xc0fe)
        or a
        jr z,.cpu_not_falling
        dec a
        ld (0xc0fe),a
        ld a,(0xc093)
        cp 157
        jr nc,.cpu_land
        add a,2
        ld (0xc093),a
        jp cpu_draw_only
.cpu_land:
        ld a,159
        ld (0xc093),a
        jp cpu_draw_only
.cpu_not_falling:
        ld a,(0xc095)
        or a
        jp nz,cpu_draw_only
        call cpu_bar_state
        call cpu_jump_step
        ld a,(0xc0c5)
        add a,2
        cp 30
        jr c,.cpu_phase_save
        sub 30
.cpu_phase_save:
        ld (0xc0c5),a
        ; CPU power builds up from zero, as in the arcade, where the POWER
        ; bar is the runner's movement accumulator. C097 holds four times
        ; the power (0..176, i.e. 44 of 48, ~92%); every update closes 1/32
        ; of the gap: at ~30 updates/s about 37% after 0.5 s, 61% after 1 s
        ; and 98% after 4 s, like the recorded arcade race.
        ld a,(0xc097)
        ld b,a
        ld a,176
        sub b
        srl a
        srl a
        srl a
        srl a
        srl a
        inc a
        add a,b
        cp 177
        jr c,.cpu_power_ready
        ld a,176
.cpu_power_ready:
        ld (0xc097),a
        ; Same rule as the player: four pixels each time the accumulated
        ; power reaches 48. Full power is four pixels per update.
        srl a
        srl a
        ld b,a
        ld a,(0xc096)
        add a,b
        cp 48
        jr nc,.cpu_step_ready
        ld (0xc096),a
        jr .animate
.cpu_step_ready:
        sub 48
        ld (0xc096),a
        ld a,(0xc095)
        or a
        jr nz,.animate
        ld a,(0xc092)
        cp 100
        jr nc,.advance_camera
        add a,4
        ld (0xc092),a
        jr .animate
.advance_camera:
        ld a,(0xc091)
        cp 9
        jr c,.advance
        ld a,(0xc090)
        cp 184
        jr c,.advance
        ld a,1
        ld (0xc095),a
        xor a
        ld (0xc094),a
        ld (0xc0c4),a
        ld a,159
        ld (0xc093),a
        jr .animate
.advance:
        ld a,(0xc090)
        add a,4
        ld (0xc090),a
        jr nc,.animate
        ld a,(0xc091)
        inc a
        ld (0xc091),a
.animate:
cpu_draw_only:
        ; Reserve the player's camera while redrawing the CPU's viewport.
        ld a,(0xc006)
        ld (0xc09b),a
        ld a,(0xc00c)
        ld (0xc09c),a
        ld a,(0xc090)
        ld (0xc006),a
        ld a,(0xc091)
        ld (0xc00c),a
        ld a,112
        ld (0xc09a),a
        call scroll_track
        xor a
        ld (0xc09a),a
        ld a,(0xc09b)
        ld (0xc006),a
        ld a,(0xc09c)
        ld (0xc00c),a
        ; Reuse the player command block after the upper sprite was issued.
        call wait_cmd
        ld hl,cpu_sprite_template
        ld de,0xc0a0
        ld bc,21
        ldir
        ld a,(0xc0fe)
        or a
        jr z,.cpu_check_finished
        ; A runner knocked from the bars keeps the seated pose while descending,
        ; then remains seated briefly after touching the ground.
        ld a,48
        ld (0xc0a0),a
        ld (0xc0a8),a
        xor a
        ld (0xc0a2),a
        ld a,11
        ld (0xc0a3),a
        ld a,(0xc092)
        sub 8
        ld (0xc0a4),a
        jr .cpu_y
.cpu_check_finished:
        ld a,(0xc095)
        ld b,a
        ld a,(0xc0d9)
        or b
        jr z,.cpu_running_pose
.cpu_rest_pose:
        ld a,176
        ld (0xc0a0),a
        ld a,(0xc092)
        ld (0xc0a4),a
        jr .cpu_y
.cpu_running_pose:
        ld a,(0xc0c5)
        rrca
        rrca
        and 3
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        ld (0xc0a0),a
        ld a,(0xc094)
        or a
        jr z,.cpu_pose_ready
        ld a,128
        ld (0xc0a0),a
        ld a,48
        ld (0xc0a8),a
        ld a,(0xc092)
        sub 8
        ld (0xc0a4),a
        jr .cpu_y
.cpu_pose_ready:
        ld a,(0xc092)
        ld (0xc0a4),a
.cpu_y:
        ld a,(0xc093)
        ld (0xc0a6),a
        ld a,(0xc0d8)
        ld (0xc0a7),a
        ld a,(0xc0c4)
        or a
        jr z,.draw_cpu
        ; Six original hanging poses, mirrored in the CPU's green palette.
        ld a,(0xc0c5)
.cpu_mod30:
        cp 30
        jr c,.cpu_phase
        sub 30
        jr .cpu_mod30
.cpu_phase:
        ld b,a
        ld c,0
.cpu_phase_loop:
        ld a,b
        cp 5
        jr c,.cpu_phase_done
        sub 5
        ld b,a
        inc c
        jr .cpu_phase_loop
.cpu_phase_done:
        ld a,c
        cp 5
        jr z,.cpu_last_hang
        ld e,a
        add a,a
        add a,e
        add a,a
        add a,a
        add a,a
        add a,a
        ld (0xc0a0),a
        xor a
        ld (0xc0a2),a
        jr .cpu_hang_coords
.cpu_last_hang:
        xor a
        ld (0xc0a0),a
        ld a,64
        ld (0xc0a2),a
.cpu_hang_coords:
        ld a,10
        ld (0xc0a3),a
        ld a,(0xc092)
        sub 8
        ld (0xc0a4),a
        ld a,136
        ld (0xc0a6),a
        ld a,48
        ld (0xc0a8),a
        ld a,56
        ld (0xc0aa),a
.draw_cpu:
        ld hl,0xc0a0
        call command
        ret

; Crude CPU obstacle handling, based on the same estimated wall ranges.
; This is a timing prototype, not the arcade opponent AI.
cpu_bar_state:
        xor a
        ld (0xc0c4),a
        ld a,(0xc090)
        ld l,a
        ld a,(0xc091)
        ld h,a
        ld a,(0xc092)
        ld e,a
        ld d,0
        add hl,de
        ld de,16
        add hl,de
        ld de,2032
        or a
        sbc hl,de
        ret c
        ld de,398
        or a
        sbc hl,de
        ret nc
        ld a,1
        ld (0xc0c4),a
        xor a
        ld (0xc094),a
        ret

cpu_jump_step:
        ld a,(0xc0c4)
        or a
        ret nz
        ld a,(0xc095)
        or a
        ret nz
        ld a,(0xc094)
        or a
        jr nz,.in_jump
        ; Leading edge in world coordinates, looking 18 pixels ahead.
        ld a,(0xc090)
        ld l,a
        ld a,(0xc091)
        ld h,a
        ld a,(0xc092)
        ld e,a
        ld d,0
        add hl,de
        ld de,46
        add hl,de
        ld (0xc0c0),hl
        ld ix,wall_table
.next_wall:
        ld e,(ix+0)
        ld d,(ix+1)
        ld a,d
        cp 0xff
        ret z
        ld hl,(0xc0c0)
        or a
        sbc hl,de
        jr c,.next_entry
        ; Only trigger if our leading edge has not yet passed the obstacle.
        ld de,30
        or a
        sbc hl,de
        jr nc,.next_entry
        ld a,(ix+4)
        ld (0xc09d),a
        ld e,(ix+2)
        ld d,(ix+3)
        ld hl,20
        add hl,de
        ld (0xc09e),hl
        ld a,1
        ld (0xc094),a
        jr .in_jump
.next_entry:
        ld de,5
        add ix,de
        jr .next_wall
.in_jump:
        ld a,(0xc094)
        ld e,a
        ld d,0
        ld hl,jump_heights-1
        add hl,de
        ld a,159
        sub (hl)
        ; High walls need the same additional height as the provisional ascent.
        ld b,a
        ld a,(0xc09d)
        cp 23
        ld a,b
        jr nc,.save_y
        sub 16
        cp 112
        jr nc,.save_y
        ld a,112
.save_y:
        ld (0xc093),a
        ld a,(0xc094)
        inc a
        cp 25
        jr c,.save_phase
        ; Hold at the obstacle's top until the actor has passed it.
        ld a,(0xc090)
        ld l,a
        ld a,(0xc091)
        ld h,a
        ld a,(0xc092)
        ld e,a
        ld d,0
        add hl,de
        ld de,28
        add hl,de
        ld de,(0xc09e)
        or a
        sbc hl,de
        jr nc,.finish_jump
        ld a,(0xc09d)
        add a,104
        ld (0xc093),a
        ld a,24
        jr .save_phase
.finish_jump:
        xor a
        ld (0xc094),a
        ld a,159
        ld (0xc093),a
        ret
.save_phase:
        ld (0xc094),a
        ret

; Minimal prototype UI: elapsed countdown and two energy indicators.
; Instructor at the starting line and, independently in each lane, at goal.
instructor_step:
        xor a
        ld (0xc0bb),a
        ld a,(0xc0d9)
        or a
        jr z,.start_pose
        ; Arcade goal gesture after the player's arrival: arms crossed for
        ; 1.2 s, baton raised for 0.2 s, baton pointed at the runner until
        ; 2.4 s, then arms crossed again.
        ld a,(0xc0b8)
        or a
        jr z,.goal_begin
        cp 2
        ld a,3
        jr z,.pose_ready
        jr .goal_elapsed
.goal_begin:
        ld a,1
        ld (0xc0b8),a
        ld a,(0xfc9e)
        ld (0xc0b9),a
.goal_elapsed:
        ld a,(0xc0b9)
        ld b,a
        ld a,(0xfc9e)
        sub b
        ld c,a
        ld a,12
        call tenths_to_jiffies
        cp c
        ld a,3
        jr nc,.pose_ready
        ld a,14
        call tenths_to_jiffies
        cp c
        ld a,5
        jr nc,.pose_ready
        ld a,24
        call tenths_to_jiffies
        cp c
        ld a,4
        jr nc,.pose_ready
        ld a,2
        ld (0xc0b8),a
        ld a,3
        jr .pose_ready
.start_pose:
        ld a,(0xc0ba)
        or a
        ld a,2
        jr z,.pose_ready
        ld hl,(0xfc9e)
        ld de,(0xc0da)
        or a
        sbc hl,de
        ld a,(0xc0dd)
        rrca
        cp l
        ld a,0
        jr nc,.pose_ready
        ld a,1
.pose_ready:
        ld (0xc0be),a
        ld a,(0xc006)
        ld l,a
        ld a,(0xc00c)
        ld h,a
        call .position
        jr c,.lower
        ld (0xc0bc),a
        ld a,1
        ld (0xc0bb),a
        ld a,(0xc0bc)
        ld c,39
        call .draw
.lower:
        ld a,(0xc090)
        ld l,a
        ld a,(0xc091)
        ld h,a
        call .position
        ret c
        ld (0xc0bd),a
        ld a,(0xc0bb)
        or 2
        ld (0xc0bb),a
        ld a,(0xc0bd)
        ld c,139
        jp .draw
.position:
        ld a,h
        or a
        jr nz,.goal_position
        ld a,l
        cp 144
        jr nc,.hidden
        ld a,144
        sub l
        or a
        ret
.goal_position:
        cp 9
        jr nz,.hidden
        ld a,l
        cp 160
        jr c,.hidden
        ; Arcade place: x=183 once the camera stops at 2488 (l=184).
        ld a,0x6f
        sub l
        or a
        ret
.hidden:
        scf
        ret
.draw:
        ld (0xc0bf),a
        ld a,c
        ld (0xc0b7),a
        ld hl,instructor_template
        ld de,0xc300
        ld bc,21
        ldir
        ; Poses 0-3 at y=2688, poses 4-5 at y=2752; 48-pixel columns.
        ld a,(0xc0be)
        ld c,0x80
        cp 4
        jr c,.pose_column
        sub 4
        ld c,0xc0
.pose_column:
        ld b,a
        add a,a
        add a,b
        add a,a
        add a,a
        add a,a
        add a,a
        ld (0xc300),a
        ld a,c
        ld (0xc302),a
        ld a,(0xc0bf)
        ld (0xc304),a
        ld a,(0xc0b7)
        ld (0xc306),a
        ld a,(0xc0d8)
        ld (0xc307),a
        ld hl,0xc300
        jp command

instructor_template:
        dw 0,2688,144,39,48,64
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40

; A = tenths of a second (1..42); returns A = BIOS jiffies at 50 or 60 Hz.
tenths_to_jiffies:
        push bc
        ld b,a
        ld a,(0xc0dd)
        cp 50
        ld c,5
        jr z,.rate
        ld c,6
.rate:
        xor a
.multiply:
        add a,c
        djnz .multiply
        pop bc
        ret

; Player at the goal, as in the arcade: bent and panting, then standing up
; and raising an arm, since reaching the goal in time passes the event.
; Overrides the command block at C030 with a 32x64 cell at VRAM y=2816.
goal_pose:
        ld a,(0xc0d5)
        or a
        ret z
        ld a,(0xc005)
        cp 55
        ret nz                 ; the final jump still uses the airborne sprite
        ld e,0
        ld a,(0xc418)
        or a
        jr z,.selected
        ld hl,(0xfc9e)
        ld bc,(0xc419)
        or a
        sbc hl,bc
        ld e,3
        ld a,h
        or a
        jr nz,.selected
        ld e,0
        ld a,37
        call tenths_to_jiffies
        cp l
        jr nc,.selected
        inc e
        ld a,39
        call tenths_to_jiffies
        cp l
        jr nc,.selected
        inc e
        ld a,41
        call tenths_to_jiffies
        cp l
        jr nc,.selected
        inc e
.selected:
        ld a,e
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        add a,96
        ld (0xc030),a
        xor a
        ld (0xc031),a
        ld (0xc032),a
        ld (0xc039),a
        ld (0xc03b),a
        ld a,11
        ld (0xc033),a
        ld a,32
        ld (0xc038),a
        ld a,64
        ld (0xc03a),a
        ld a,(0xc005)
        sub 16
        ld (0xc036),a
        ret

ui_step:
        ld a,(0xc0d9)
        or a
        jr nz,.render
        ; As in the arcade, crossing the white finish line (world 2496-2518)
        ; is the goal: the clock stops while the runner goes on to his stop.
        ; C0D5 (camera end, beyond the line) also counts.
        ld a,(0xc0d5)
        or a
        jr nz,.line_crossed
        call world_centre
        ld de,2520
        or a
        sbc hl,de
        jr c,.clock
.line_crossed:
        ; The CPU may arrive first, but the player can still qualify by
        ; reaching the goal before the countdown expires.
        ld a,(0xc095)
        or a
        ld a,2
        jr nz,.record_result
        ld a,1
.record_result:
        ld (0xc0d9),a
        jr .render
.clock:
        ld a,(0xc0ba)
        or a
        jr nz,.render
        ; The game loop may miss display frames; use the BIOS JIFFY clock.
        ld hl,(0xfc9e)
        ld de,(0xc0da)
        or a
        sbc hl,de
        ld a,h
        or a
        jr nz,.one_second
        ld a,(0xc0dd)
        ld b,a
        ld a,l
        cp b
        jr c,.render
.one_second:
        ld hl,(0xc0da)
        ld a,(0xc0dd)
        ld e,a
        ld d,0
        add hl,de
        ld (0xc0da),hl
        ld a,(0xc0d0)
        or a
        jr z,.time_zero
        dec a
        ld (0xc0d0),a
        call psg_countdown      ; the last seconds and the end (Spectrum)
.time_zero:
        or a
        jr nz,.render
        ld a,1
        ld (0xc0d4),a
        ld a,3
        ld (0xc0d9),a
.render:
        ; Derive tenths from the same 50/60 Hz BIOS clock as whole seconds.
        ld a,(0xc0d9)
        or a
        jr nz,.time_parts
        xor a
        ld (0xc0de),a
        ld a,(0xc0d0)
        ld (0xc0df),a
        ld a,(0xc0ba)
        or a
        jr nz,.time_parts
        ld hl,(0xfc9e)
        ld de,(0xc0da)
        or a
        sbc hl,de
        ld a,l
        or a
        jr z,.time_parts
        ld a,(0xc0dd)
        cp 50
        ld c,5
        jr z,.tenth_divide
        ld c,6
.tenth_divide:
        ld a,l
        ld b,0
.tenth_loop:
        cp c
        jr c,.tenth_done
        sub c
        inc b
        jr .tenth_loop
.tenth_done:
        ld a,9
        sub b
        ld (0xc0de),a
        ld a,(0xc0df)
        or a
        jr z,.time_parts
        dec a
        ld (0xc0df),a
.time_parts:
        xor a
        ld (0xc0d1),a
        ld a,(0xc0df)
        cp 60
        jr c,.seconds_ready
        sub 60
        ld b,a
        ld a,1
        ld (0xc0d1),a
        ld a,b
.seconds_ready:
        ld b,0
.tens:
        cp 10
        jr c,.digits_ready
        sub 10
        inc b
        jr .tens
.digits_ready:
        ld (0xc0d3),a
        ld a,b
        ld (0xc0d2),a
        ld a,(0xc0d1)
        ld c,184
        call ui_digit
        ld a,18
        ld c,192
        call ui_digit
        ld a,(0xc0d2)
        ld c,200
        call ui_digit
        ld a,(0xc0d3)
        ld c,208
        call ui_digit
        ld a,19
        ld c,216
        call ui_digit
        ld a,(0xc0de)
        ld c,224
        call ui_digit
        call score_ui
        ; As in the arcade: PLAYER 1(NICK) with YOU MADE IT below it when the
        ; goal is reached in time (even after the CPU), YOU BLEW IT in red
        ; when the time runs out.
        ld a,(0xc0d9)
        or a
        jr z,.no_result_text
        push af
        ld hl,player_name_label
        call ui_text
        pop af
        cp 3
        ld hl,made_it_label
        jr nz,.result_label
        ld hl,blew_it_label
.result_label:
        call ui_text
.no_result_text:
        ; Two POWER legends and framed gauges. CPU energy remains indicative.
        ; The upper lane's gauge sits in the black band between the lanes
        ; (rows 114-121), as in the arcade, so the course rows 100-111 with
        ; the start and finish lines stay visible.
        ld c,114
        call ui_label
        ld c,204
        call ui_label
        ld a,96
        ld c,115
        ld b,UI_SHADOW
        call ui_bar
        ld a,96
        ld c,114
        ld b,UI_GREEN
        call ui_bar
        ld a,(0xc008)
        add a,a
        ld c,114
        ld b,UI_RED
        call ui_bar
        ld a,96
        ld c,205
        ld b,UI_SHADOW
        call ui_bar
        ld a,96
        ld c,204
        ld b,UI_GREEN
        call ui_bar
        ; The CPU bar shows its real power (C097/2, at most 88 of 96).
        ld a,(0xc095)
        or a
        ld a,0
        jr nz,.cpu_bar
        ld a,(0xc097)
        srl a
.cpu_bar:
        ld c,204
        ld b,UI_RED
        jp ui_bar

; END: glyph, destination X and Y triples, 0xff terminated (15 E, 16 N,
; 17 D), in the top band beside the clock.
; Upper lane labels at the arcade's positions: source X, source Y (low byte
; of 2516=0x9d4), width, height, destination X and Y.
player_name_label:
        db 0,0xd4,112,10,17,22
made_it_label:
        db 112,0xd4,88,10,41,38
blew_it_label:
        db 0,0xe4,88,10,41,38

; HL -> label descriptor above; copies it from the UI strip to the page.
ui_text:
        push hl
        ld hl,ui_digit_template
        ld de,0xc0e0
        ld bc,21
        ldir
        pop hl
        ld a,(hl)
        ld (0xc0e0),a
        inc hl
        ld a,(hl)
        ld (0xc0e2),a
        inc hl
        ld a,(hl)
        ld (0xc0e8),a
        inc hl
        ld a,(hl)
        ld (0xc0ea),a
        inc hl
        ld a,(hl)
        ld (0xc0e4),a
        inc hl
        ld a,(hl)
        ld (0xc0e6),a
        ld a,(0xc0d8)
        ld (0xc0e7),a
        ld hl,0xc0e0
        jp command

; Single game score, as in the arcade without HI or 2P: a red 1P and, after
; one blank cell, the total C75C..C75E left-aligned from x 40 in clock digits.
score_ui:
        ld hl,score_label
        call ui_text
        ld d,40
        ld iy,score_ui_digit
        jr score_digits
score_ui_digit:
        ld c,d
        ld b,0
        jp ui_digit_at

; Decimal digits of the game score C75C..C75E, leading zeros hidden, from
; x = D in steps of 8. IY = drawing routine: A = digit, D = x (it may
; change any register).
score_digits:
        ld hl,(0xc75c)
        ld a,(0xc75e)
        ld e,a                  ; E:HL = score
        ld ix,score_powers
        ld c,0                  ; non-zero once a digit has been shown
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
        push iy
        ld a,b
        call .draw
        pop iy
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
        ld a,l                  ; units, always shown
.draw:  jp (iy)
score_powers:
        db 0xa0,0x86,0x01, 0x10,0x27,0x00, 0xe8,0x03,0x00
        db 0x64,0x00,0x00, 0x0a,0x00,0x00, 0
score_label:
        db 96,0xe4,16,10,16,3   ; 1P from the UI strip (x 96, y 2532)

; A = digit, C = destination X (ui_digit: Y=0; ui_digit_at: Y=B).
ui_digit:
        ld b,0
ui_digit_at:
        add a,a
        add a,a
        add a,a
        ld (0xc0d6),a
        ld a,c
        ld (0xc0d7),a
        push bc
        ld hl,ui_digit_template
        ld de,0xc0e0
        ld bc,21
        ldir
        pop bc
        ld a,b
        ld (0xc0e6),a
        ld a,(0xc0d6)
        ld (0xc0e0),a
        ld a,(0xc0d7)
        ld (0xc0e4),a
        ld a,(0xc0d8)
        ld (0xc0e7),a
        ld hl,0xc0e0
        jp command

; A = width in pixels, B = colour, C = destination Y.
ui_bar:
        or a
        ret z
        push af
        ld a,b
        add a,a
        add a,a
        add a,a
        add a,a
        or b
        ld (0xc0d2),a
        pop af
        ld (0xc0d6),a
        ld a,c
        ld (0xc0d7),a
        ld hl,ui_bar_template
        ld de,0xc0e0
        ld bc,21
        ldir
        ld a,(0xc0d6)
        ld (0xc0e8),a
        ld a,(0xc0d7)
        ld (0xc0e6),a
        ld a,(0xc0d8)
        ld (0xc0e7),a
        ld a,(0xc0d2)
        ld (0xc0f0),a
        ld (0xc0f1),a
        ld hl,0xc0e0
        jp command

; C = destination Y for the POWER legend.
ui_label:
        ld a,c
        ld (0xc0d7),a
        ld hl,ui_label_template
        ld de,0xc0e0
        ld bc,21
        ldir
        ld a,(0xc0d7)
        ld (0xc0e6),a
        ld a,(0xc0d8)
        ld (0xc0e7),a
        ld hl,0xc0e0
        jp command

ui_digit_template:
        dw 0,2500,200,0,8,16
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
ui_bar_template:
        dw 0,0,44,104,96,6
        db 0,0x0c,0xff,0xff,UI_RED*17,UI_RED*17,0,0,0x20
ui_label_template:
        dw 160,2500,4,104,40,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40

cpu_sprite_template:
        dw 0,2432,64,159,32,48
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40

 ; Redraw the top lane from 256x112 course pages stored in VRAM.
scroll_track:
        ld hl,scroll_template
        ld de,0xc060
        ld bc,21
        ldir
        ld a,(0xc09a)
        ld (0xc066),a
        ld a,(0xc0d8)
        ld (0xc067),a
        ; source Y = 768 + 128 * high byte of world offset
        ld a,(0xc00c)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,768
        add hl,de
        ld (0xc062),hl
        ld a,(0xc006)
        ld (0xc060),a
        ld e,a
        ld d,0
        ld hl,256
        or a
        sbc hl,de
        ld (0xc068),hl
        ld a,(0xc006)
        or a
        jr z,.whole
        ld hl,0xc060
        call command
        ld hl,0
        ld (0xc060),hl
        ld a,(0xc006)
        ld e,a
        ld d,0
        ld hl,256
        or a
        sbc hl,de
        ld (0xc064),hl
        ld (0xc068),de
        ld hl,(0xc062)
        ld de,128
        add hl,de
        ld (0xc062),hl
.whole:
        ld hl,0xc060
        call command
        ret

scroll_template:
        dw 0,768,0,0,256,112
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40

; Keep the qualified result and show the bonus and event map. The gallery is
; not available yet, so the map remains visible with STEP 1 flashing.
; c410=seconds, c411=tenths, c412=qualified, c413=bonus seconds,
; c414=bonus points (word), c416=CPU reached first, c417=next time,
; c418=stage (0 race, 1 result, 2 bonus, 3 map), c419=result JIFFY.
progress_tick:
        ld a,(0xc418)
        or a
        jr nz,.wait_result
        ld a,(0xc0df)
        ld (0xc410),a
        ld a,(0xc0de)
        ld (0xc411),a
        ld a,1
        ld (0xc412),a
        ld a,(0xc095)
        ld (0xc416),a
        ld a,(0xc410)
        srl a
        cp 6
        jr c,.bonus_ready
        ld a,5
.bonus_ready:
        ld (0xc413),a
        add a,35
        ld (0xc417),a
        ld a,(0xc413)
        add a,a
        ld e,a
        ld d,0
        ld hl,progress_points
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (0xc414),de
        call add_score          ; time bonus on top of the race points
        ld hl,(0xfc9e)
        ld (0xc419),hl
        ld a,1
        ld (0xc418),a
.wait_result:
        ld hl,(0xfc9e)
        ld de,(0xc419)
        or a
        sbc hl,de
        push hl
        ld a,(0xc0dd)
        ld e,a
        ld d,0
        ; Six seconds at the goal: the arcade raises the arm after ~4.1 s.
        ld hl,0
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        ex de,hl
        pop hl
        or a
        sbc hl,de
        ret c
        jp progress_screens

progress_points:
        dw 0,1000,2000,4000,6000,8000

progress_screens:
        ld a,9                  ; bonus music
        call psg_play
        call display_off        ; off from the next frame on
        ld hl,progress_palette
        call intro_set_palette
        ld a,15
        out (0x64),a
        ld a,PROGRESS_BLACK
        out (0x63),a
        xor a
        ld (0xc0b6),a
        ld a,58
        call intro_frame
        ld a,(0xc413)
        call progress_marker
        ld a,2
        ld (0xc418),a
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld hl,(0xfc9e)
        ld (0xc419),hl
.wait_bonus:
        ld hl,(0xfc9e)
        ld de,(0xc419)
        or a
        sbc hl,de
        ld a,(0xc0dd)
        add a,a
        add a,a
        cp l
        jr nc,.wait_bonus
        call psg_wait_song      ; the bonus music ends first
        call psg_stop           ; the map is silent
        call display_off        ; off from the next frame on
        ld hl,map_palette
        call intro_set_palette
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        ld a,1
        ld (0xc0b6),a
        ld a,62
        call intro_frame
        xor a
        call progress_map_light
        xor a
        ld (0xc0b6),a
        ld a,62
        call intro_frame
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld a,3
        ld (0xc418),a
        ld hl,(0xfc9e)
        ld (0xc419),hl
.blink_map:
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
        ld de,(0xc419)
        or a
        sbc hl,de
        push hl
        ld a,(0xc0dd)
        ld e,a
        ld d,0
        ld hl,0
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        add hl,de
        ex de,hl
        pop hl
        or a
        sbc hl,de
        jp nc,shoot_start
        jr .blink_map

 ; Draw the selected 18x8 marker from the picture's extra data, whose bank
 ; intro_frame leaves mapped. A=bonus bracket, c0b6=VRAM page.
progress_marker:
        push af
        ld e,a
        ld d,0
        ld hl,progress_marker_rows
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
        ld de,(0xc0c9)         ; extra data of the picture (intro_frame)
        add hl,de
        push hl
        pop ix
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
progress_marker_rows:
        db 197,181,165,149,133,117   ; the arcade's rows (tools/build_progress_assets.py)

; Draw completed map squares white in the hidden page. A=0 for Step 1,
; A=1 for Steps 1 and 2; the off page remains the common gold base image.
progress_map_light:
        ld (0xc0b7),a
        ld hl,progress_square
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
progress_square:
        dw 0,0,16,182,16,29
        db 0,0x0c,0xff,0xff,0x99,0x99,0,0,0x20

; D blocks of 256 bytes from the mapped ROM bank to VRAM.
; Show the title until SPACE, RETURN or joystick button, then play the
; captured character introduction. All frames use their own B1 palette.
; The cartridge's start address: asks init for the power-on screens.
boot:
        ld a,0xa5
        ld (0xd0f3),a
        jp init

show_intro:
        xor a
        ld (0xc0b3),a
        ld (0xc0b6),a
        ; The border (all the screen while the display is off) goes to an
        ; entry that is black now and in the title, then the palette loads:
        ; entry 0 is cream in the title (a cream line otherwise).
        ld a,TITLE_BLACK
        call border_black
        ld hl,title_palette
        call intro_set_palette
        ld a,19
        call intro_frame
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ld a,1
        ld (0xc0b3),a
        ei
.wait_start:
        ld a,8
        call 0x0141
        bit 0,a
        jr z,.start
        ld a,7
        call 0x0141
        bit 7,a
        jr z,.start
        xor a
        call 0x00d8
        or a
        jr nz,.start
        ld a,1
        call 0x00d8
        or a
        jr z,.wait_start
.start:
        ; F1 is sampled only when starting; f207 persists for this game.
        ld a,6
        call 0x0141
        bit 5,a
        ld a,0
        jr nz,.flag_selected
        inc a
.flag_selected:
        ld (0xf207),a
        ld a,2
        ld (0xc0b3),a
        ld a,1                  ; PLAYER READY music, as the arcade after START
        call psg_play
        ; Hide the title while changing palettes, so it cannot flash in the
        ; presentation's colours. The first new frame re-enables display.
        call display_off        ; off from the next frame on
        ; The arcade introduction frame by frame (src/intro_slide.asm, then
        ; the region engine, tools/build_intro_anim.py).
        ld a,(0xd0fe)
        cp 0xa5
        jr z,.intro_done        ; tools/test_skip_intro.tcl
        xor a
        ld (PRE_HOME),a
        ld hl,intro_slide
        ld (PRE_HOOK),hl
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ld b,48
.black:
        out (0x61),a            ; black while the pictures load
        djnz .black
        ld a,15                 ; then the border to entry 0 (cream before)
        out (0x64),a
        xor a
        out (0x63),a
        ld hl,prelude_intro
        call prelude_screen
.intro_done:
        di
        ; Hide the last intro frame before switching to the race palette.
        ; Initialization enables the display after the race image is loaded.
        call display_off        ; off from the next frame on
        ; The intro border uses palette entry 15, which is red in the race.
        ; Make entry 0 black and select it before replacing the palette.
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        out (0x61),a
        out (0x61),a
        out (0x61),a
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        ld hl,palette
        call intro_set_palette
        ld a,15
        out (0x64),a
        xor a
        out (0x63),a
        xor a
        ld (0xc0b6),a
        ld a,1
        call intro_frame
        ld a,3
        ld (0xc0b3),a
        ret

; A = palette entry: made black, then the border (R15) uses it. Before a
; palette is loaded with the display off, so the border never shows one of
; its colours. Keeps every register but A and F.
border_black:
        push bc
        ld b,a
        ld a,14
        out (0x64),a
        ld a,b
        add a,a
        add a,a
        out (0x63),a
        xor a
        out (0x61),a
        out (0x61),a
        out (0x61),a
        ld a,15
        out (0x64),a
        ld a,b
        out (0x63),a
        pop bc
        ret

intro_set_palette:
        ld a,14
        out (0x64),a
        xor a
        out (0x63),a
        ld bc,0x3061
        otir
        ret

; A = picture (its key in image_table, tools/build_image_pack.py): decompress
; it to the hidden page and present it. Leaves the bank of the picture's
; extra data mapped, its address in C0C9 (bank in C0C8).
intro_frame:
        ld (0xc0b2),a
        xor a
        out (0x64),a
        out (0x63),a
        ld a,(0xc0b6)
        rrca
        out (0x63),a
        xor a
        out (0x63),a
        ld a,(0xc0b2)
        call image_stream
        ld a,18
        out (0x64),a
        ld a,(0xc0b6)
        out (0x63),a
        ret

; A = picture key: its RLE stream (tools/build_image_pack.py) to the
; current VRAM address. Literal runs go out with OTIR, as fast as raw data.
image_stream:
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
        ld (0xc0cb),a          ; stream bank, advanced at 0xC000
        ld (0x7000),a
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        ld (0xc0c8),a          ; extra data bank
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld (0xc0c9),bc         ; extra data address
        ex de,hl
        ld c,0x60
.read_unit:
        ld a,(hl)
        inc hl
        or a
        jr z,.done
        jp p,.literal
        sub 128
        jr z,.next_bank        ; 128: the stream goes on in the next bank
        ld b,a                 ; repeat: 4 bytes per loop
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

upload_blocks:
        ld bc,0x0060
        otir
        dec d
        jr nz,upload_blocks
        ret

wait_cmd:
        in a,(0x65)
        rrca
        jr c,wait_cmd
        ret
command:
        call wait_cmd
        ld a,32
        out (0x64),a
        ld bc,21*256+0x63
        otir
        ret
jump_heights:
        db 8,8,14,14,20,20,24,24,28,28,30,30,32,32,32,32
        db 32,32,30,30,28,28,24,24,20,20,14,14,8,8,0,0
; Step 1 lost by the clock: chin-ups from the distance left to the goal,
; the white line (camera + runner x = 2504: centre 2520, as ui_step). Arcade (0xc4ea, 0xc64f):
; penalty up to 256 of its 2712 pixels, 5..10 chin-ups in 32-pixel bands;
; scaled to the 2524 pixels of this course. Carry: waiting for the penalty.
step1_penalty:
        ld a,(0xc00c)
        ld h,a
        ld a,(0xc006)
        ld l,a
        ld a,(0xc000)
        ld e,a
        ld d,0
        add hl,de
        ex de,hl
        ld hl,2504
        or a
        sbc hl,de
        jr nc,.distance
        ld hl,0
.distance:
        ld de,step1_bands
.band:
        ld a,(de)
        inc de
        ld c,a
        ld a,(de)
        inc de
        ld b,a                 ; BC = limit
        ld a,(de)
        inc de
        or a
        sbc hl,bc
        add hl,bc
        jr nc,.band
        ld b,1
        jp 0xf210
step1_bands:
        dw 30
        db 5
        dw 60
        db 6
        dw 89
        db 7
        dw 119
        db 8
        dw 149
        db 9
        dw 239
        db 10
        dw 0xffff
        db 0
; Copied to 0xf210 by init; every step calls it while showing a lost result
; (relative jumps only). A = chin-ups (0 = no penalty), B = step lost.
; Five seconds after the result: the penalty (bank 123, src/penalty.asm) if
; it is due and not used in this game, otherwise GAME OVER and the title, as
; in the arcade. Until then carry is set: the step keeps showing its result.
pen_try_code:
        ld c,a
        ld hl,0xf206
        ld a,(hl)
        or a
        jr nz,.armed
        inc (hl)
        ld hl,(0xfc9e)
        ld (0xf204),hl
.armed:
        ld hl,(0xfc9e)
        ld de,(0xf204)
        or a
        sbc hl,de
        ld a,(0x002b)
        rlca
        ld de,300
        jr nc,.rate
        ld de,250
.rate:
        or a
        sbc hl,de
        ret c
        di
        ld sp,0xf000
        xor a
        ld (0xf206),a
        ld a,b
        ld (0xf202),a
        ld a,123
        ld (0x6000),a
        ld a,c
        or a
        jr z,.game_over
        ld a,(0xf200)
        or a
        jr nz,.game_over
        ld a,c
        ld (0xf201),a
        ld a,1
        ld (0xf200),a
        jp 0x4010              ; penalty
.game_over:
        jp 0x400a              ; GAME OVER, then the title
pen_try_end:
        include "shoot_b1.asm"
background_cmd:
        dw 0,0,0,256,256,212
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40

restore_template:
        dw 56,311,56,55,48,48
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
sprite_template:
        dw 0,512,64,55,32,48
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
        include "../build/demo/ui.inc"
        include "../build/demo/intro.inc"
        include "../build/demo/image-table.inc"
        include "../build/demo/progress.inc"
        include "../build/demo/shoot.inc"
        include "../build/demo/intro-anim.inc"
        include "intro_slide.asm"
        include "../build/psg/driver.inc"
        include "psg_music.asm"
        include "psg_calls.asm"
regs:   db 0x81,0,0x42,0
settings: db 0,0,0,0,0,0,0,0
palette: incbin "../build/demo/palette.bin"
title_palette: incbin "../build/demo/title-palette.bin"
progress_palette: incbin "../build/demo/progress-palette.bin"
map_palette: incbin "../build/demo/map-palette.bin"
shoot_palette: incbin "../build/demo/shoot-palette.bin"
        assert $ <= 0x8000
        ds 0x8000-$,0xff
