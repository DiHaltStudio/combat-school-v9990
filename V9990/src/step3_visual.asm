; Standalone V9990 vertical camera experiment. Provisional graphics and rules.
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
        ld hl,palette
        ld bc,0x3061
        otir
        ; A 256x256 diagnostic surface at y=512, supplied by banks 1-2.
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
        ; The two test runners are at y=768.
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
        ld d,32
        call upload
        ; Arcade runner poses (32x48 cells) and labels at y=3584, banks 24-26.
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        ld a,7
        out (0x63),a
        ld a,24
        ld (0xc743),a
.load_actors:
        ld a,(0xc743)
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ld a,(0xc743)
        inc a
        ld (0xc743),a
        cp 27
        jr nz,.load_actors
        ; Arcade river objects (boats and logs) at y=1024, banks 4-5. The
        ; river and the goal themselves are part of the course image.
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        ld a,2
        out (0x63),a
        ld a,4
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ld a,5
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ; Larger 24x32 actor atlas at y=1280, in ROM bank 6.
        xor a
        out (0x64),a
        out (0x63),a
        ld a,0x80
        out (0x63),a
        ld a,2
        out (0x63),a
        ld a,6
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ; Shared 256x2048 land course at VRAM y=1536, ROM banks 7-22.
        xor a
        out (0x64),a
        out (0x63),a
        out (0x63),a
        ld a,3
        out (0x63),a
        ld a,7
        ld (0xc743),a
.load_land:
        ld a,(0xc743)
        ld (0x7000),a
        ld hl,0x8000
        ld d,64
        call upload
        ld a,(0xc743)
        inc a
        ld (0xc743),a
        cp 23
        jr nz,.load_land
reset_race:
        xor a
        ld (0xc700),a
        ld (0xc701),a
        ld (0xc702),a
        ld (0xc703),a
        ld (0xc704),a
        ld (0xc705),a
        ld (0xc70e),a
        ld (0xc70f),a
        ld (0xc710),a
        ld (0xc711),a
        ld (0xc712),a
        ld (0xc713),a
        ld (0xc716),a
        ld (0xc718),a
        ld (0xc719),a
        ld (0xc71a),a
        ld (0xc71b),a
        ld (0xc72e),a
        ld (0xc72f),a
        ld (0xc730),a
        ld (0xc735),a
        ld (0xc736),a
        ld (0xc738),a
        ld (0xc739),a
        ld (0xc73a),a
        ld (0xc73b),a
        ld (0xc73f),a
        ld (0xc740),a
        ld (0xc741),a
        ld (0xc744),a
        ld (0xc745),a
        ld (0xc746),a
        ld (0xc756),a
        ld (0xc757),a
        ld (0xc762),a          ; fractional pace accumulators
        ld (0xc763),a
        ld (0xc770),a          ; boarding countdowns (player, CPU)
        ld (0xc771),a
        ld (0xc777),a          ; ticks since the previous update
        ld (0xc778),a
        ld (0xc774),a          ; goal timers (player, CPU)
        ld (0xc775),a
        ld (0xc776),a          ; tenths shown by the clock
        ; The arcade gives 45 seconds (plus the shooting bonus in the game).
        ld a,45
        ld (0xc731),a
        ld hl,(0xfc9e)
        ld (0xc732),hl
        ld a,(0x002b)
        bit 7,a
        ld a,60
        jr z,.clock_rate_ready
        ld a,50
.clock_rate_ready:
        ld (0xc734),a
        ; Free boats where the arcade has them, inside the river.
        ld hl,2162
        ld (0xc71e),hl
        ld hl,2258
        ld (0xc720),hl
        ld a,40
        ld (0xc71c),a
        ld a,88
        ld (0xc71d),a
        ld a,32
        ld (0xc714),a
        ld a,72
        ld (0xc715),a
        ; Standalone test ROM only (tools/build_step3_integrated.py removes
        ; it): the game score starts at zero.
        xor a
        ld (0xc75c),a
        ld (0xc75d),a
        ld (0xc75e),a
        ld a,4                  ; Iron-Man Race music (src/psg_calls.asm)
        call psg_play
        ei
loop:
        ; Ticks of the BIOS clock since the previous update (1..5): movement
        ; follows real time, so busy scenes do not slow the runners down.
        ld a,(0xc778)
        ld b,a
        ld a,(0xfc9e)
        ld (0xc778),a
        sub b
        jr nz,.dt_some
        inc a
.dt_some:
        cp 6
        jr c,.dt_ready
        ld a,5
.dt_ready:
        ld (0xc777),a
        ; Arcade water: pen 15 rotates through four blues every 8 ticks.
        ld a,14
        out (0x64),a
        ld a,60
        out (0x63),a
        ld a,(0xfc9e)
        rrca
        rrca
        rrca
        and 3
        ld e,a
        add a,a
        add a,e
        ld e,a
        ld d,0
        ld hl,water_cycle
        add hl,de
        ld bc,0x0361
        otir
        ; Pen 10, the river's other blues (arcade entries 23 and 24), two
        ; steps ahead (tools/build_ironman_course.py).
        ld a,14
        out (0x64),a
        ld a,40
        out (0x63),a
        ld a,e
        add a,6
        cp 12
        jr c,.water_ahead
        sub 12
.water_ahead:
        ld e,a
        ld hl,water_cycle
        add hl,de
        ld bc,0x0361
        otir
        ; The end of the loop already waits for vblank; no second HALT here.
        call race_clock
        call result_input
        ; Arcade logs drift right across the river at 1.3 pixels per frame:
        ; C72A = position 0..151 on a 152-pixel cycle that
        ; enters 32 pixels left of the lane, C72B its fraction.
        ; Per BIOS tick: 1.3 pixels at 60 Hz (1 + 0x4d/256), 1.56 at 50 Hz
        ; (1 + 0x8f/256); as many ticks as elapsed.
        ld a,(0xc734)
        cp 50
        ld c,0x4d
        jr nz,.log_rate
        ld c,0x8f
.log_rate:
        ld a,(0xc777)
        ld b,a
.log_tick:
        ld a,(0xc72b)
        add a,c
        ld (0xc72b),a
        ld a,(0xc72a)
        adc a,1
        cp 152
        jr c,.log_cycle
        sub 152
.log_cycle:
        ld (0xc72a),a
        djnz .log_tick
        ; Remember X so a swimmer cannot climb onto a bridge from its side.
        ld a,(0xc714)
        ld (0xc750),a
        ; A finisher runs on past the line, as in the arcade, then stays
        ; at the goal while the opponent continues the race.
        ld a,(0xc72f)
        or a
        jr z,.player_input
        ld hl,(0xc700)
        ld de,0xc774
        call goal_walk
        ld (0xc700),hl
        jp .cpu
.player_input:
        ; Left/right keys or joystick steer within the 120-pixel course.
        xor a
        call 0x00d5
        or a
        jr nz,.steer
        ld a,1
        call 0x00d5
.steer:
        ld (0xc746),a
        cp 2
        jr z,.steer_right
        cp 3
        jr z,.steer_right
        cp 4
        jr z,.steer_right
        cp 6
        jr z,.steer_left
        cp 7
        jr z,.steer_left
        cp 8
        jr nz,.jump_input
.steer_left:
        ld a,(0xc714)
        cp 8
        jr c,.jump_input
        dec a
        dec a
        ld (0xc714),a
        ld a,(0xc710)
        cp 8
        jr c,.jump_input
        ld a,(0xc705)
        and 1
        jr nz,.jump_input
        ld a,(0xc714)
        cp 8
        jr c,.jump_input
        dec a
        ld (0xc714),a
        jr .jump_input
.steer_right:
        ld a,(0xc714)
        cp 96
        jr nc,.jump_input
        inc a
        inc a
        ld (0xc714),a
        ld a,(0xc710)
        cp 8
        jr c,.jump_input
        ld a,(0xc705)
        and 1
        jr nz,.jump_input
        ld a,(0xc714)
        cp 96
        jr nc,.jump_input
        inc a
        ld (0xc714),a
.jump_input:
        ; Update the player's surface after steering; block water -> deck.
        ld hl,(0xc700)
        ld a,(0xc756)
        ld b,a
        ld a,(0xc714)
        call check_bridge_surface
        jr nc,.steer_surface_ok
        ld a,(0xc750)
        ld (0xc714),a
        ld a,(0xc758)
.steer_surface_ok:
        ld (0xc756),a
        ; M or joystick button 2 starts a jump on the press edge.
        ld a,4
        call 0x0141
        bit 2,a
        ld a,0xff
        jr z,.jump_read
        ld a,2
        call 0x00d8
.jump_read:
        ld b,a
        ld a,(0xc70e)
        ld c,a
        ld a,b
        ld (0xc70e),a
        or a
        jr z,.jump_tick
        ld a,c
        or a
        jr nz,.jump_tick
        ld a,(0xc756)
        or a
        jr nz,.jump_tick
        ld a,(0xc70f)
        or a
        jr nz,.jump_tick
        ld a,(0xc712)
        or a
        jr nz,.jump_tick
        ld a,(0xc701)
        cp 8
        jr c,.begin_jump
        cp 12
        jr c,.jump_tick
.begin_jump:
        ld a,25
        ld (0xc70f),a
.jump_tick:
        ld a,(0xc70f)
        or a
        jr z,.read_run
        dec a
        ld (0xc70f),a
.read_run:
        ; Each new SPACE / joystick button 1 press adds running energy.
        xor a
        call 0x00d8
        or a
        jr nz,.run_read
        ld a,1
        call 0x00d8
.run_read:
        ld b,a
        ld a,(0xc711)
        ld c,a
        ld a,b
        ld (0xc711),a
        or a
        jr z,.decay
        ld a,c
        or a
        jr nz,.decay
        ld a,(0xc710)
        ; Each press adds a little POWER, rising like the arcade gauge.
        add a,2
        cp 13
        jr c,.save_energy
        ld a,12
.save_energy:
        ld (0xc710),a
.decay:
        ld a,(0xc705)
        and 3
        jr nz,.player_tick
        ld a,(0xc710)
        or a
        jr z,.player_tick
        dec a
        ld (0xc710),a
.player_tick:
        ld a,(0xc712)
        or a
        jr z,.player_move
        dec a
        ld (0xc712),a
        jp .cpu
.player_move:
        ld a,(0xc72f)
        or a
        jr z,.player_racing
        ld hl,(0xc700)
        ld de,0xc774
        call goal_walk
        ld (0xc700),hl
        jp .cpu
.player_racing:
        ; Turning supplies a small amount of power even without SPACE.
        ld a,(0xc746)
        cp 3
        jr c,.normal_power
        cp 8
        jr nc,.normal_power
        ld a,(0xc710)
        cp 3
        jr nc,.normal_power
        ld a,3
        ld (0xc710),a
.normal_power:
        ld a,(0xc710)
        or a
        jp z,.cpu
        ; Arcade pace: energy x 8/16 pixels per update (~30 per second);
        ; full power gives 180 px/s, the arcade player's top speed in MAME
        ; (3 pixels per frame).
        add a,a
        add a,a
        add a,a
        ld b,a
        ld a,(0xc756)
        ld c,a
        ld a,(0xc71a)
        ld e,a
        ld a,(0xc701)
        call water_speed
        ld a,(0xc770)
        or a
        jp nz,.cpu
        ld hl,0xc762
        call speed_pixels
        jp z,.cpu
        ld (0xc75b),a
.player_advance:
        ld hl,(0xc700)
        ld (0xc752),hl
        ld a,(0xc746)
        cp 3
        jr z,.after_progress
        cp 7
        jr z,.after_progress
        cp 4
        jr c,.forward
        cp 7
        jr nc,.forward
        ; Clamp reverse movement at the start of the course.
        ld a,h
        or a
        jr nz,.backward
        ld a,(0xc75b)
        cp l
        jr c,.backward
        ld hl,0
        jr .save_progress
.backward:
        ld a,(0xc75b)
        ld e,a
        ld d,0
        or a
        sbc hl,de
        jr nc,.save_progress
        ld hl,0
        jr .save_progress
.forward:
        ld a,(0xc75b)
        ld e,a
        ld d,0
        add hl,de
        call stride_points
.save_progress:
        ld (0xc700),hl
        ld a,(0xc756)
        ld b,a
        ld a,(0xc714)
        call check_bridge_surface
        jr nc,.player_surface_ok
        ; Water to deck going forward or back: the swimmer climbs out where
        ; the deck widens at a bridge's end (only the bridge's sides are
        ; closed, when steering), instead of being stuck in the water.
        ld a,(0xc75a)
        call land_collision_lookup
        cp 4
        jr nz,.climb_out
        ld hl,(0xc752)
        ld (0xc700),hl
        ld a,(0xc758)
        jr .player_surface_ok
.climb_out:
        xor a
.player_surface_ok:
        ld (0xc756),a
.after_progress:
        ld a,(0xc756)
        or a
        jp nz,.cpu
        ld a,(0xc70f)
        or a
        jp nz,.cpu
        ld a,h
        cp 8
        jr c,.player_check_obstacle
        cp 12
        jr c,.player_water_obstacle
        jr .player_check_obstacle
.player_water_obstacle:
        ld a,(0xc714)
        call river_obstacle_collision
        jp nc,.cpu
.player_water_contact:
        ld a,(0xc71a)
        or a
        jr z,.player_water_stun
        call player_lose_boat
.player_water_stun:
        xor a
        ld (0xc740),a
        ld a,18
        ld (0xc712),a
        jr .cpu
.player_check_obstacle:
        ld a,(0xc714)
        call hazard_lookup
        or a
        jr nz,.player_contact
        ld (0xc744),a
        jr .cpu
.player_contact:
        ld b,a
        ld a,(0xc744)
        or a
        jr nz,.cpu
        ld a,1
        ld (0xc744),a
        ld a,b
        cp 2
        ld a,0
        jr nz,.player_hit_kind
        inc a
.player_hit_kind:
        ld (0xc740),a
        ld a,30
        ld (0xc712),a
        xor a
        ld (0xc710),a
.cpu:
        ld a,(0xc705)
        inc a
        ld (0xc705),a
        ; The CPU begins a jump shortly before a ground obstacle.
        ld a,(0xc73b)
        or a
        jr z,.cpu_jump_check
        dec a
        ld (0xc73b),a
        jr .cpu_stun
.cpu_jump_check:
        ld a,(0xc757)
        or a
        jr nz,.cpu_stun
        ld a,(0xc713)
        or a
        jr nz,.cpu_stun
        ld a,(0xc703)
        cp 8
        jr c,.cpu_jump_position
        cp 12
        jr c,.cpu_stun
        jr .cpu_jump_position
.cpu_jump_position:
        ld hl,(0xc702)
        ld de,36
        add hl,de
        ld a,(0xc715)
        call hazard_lookup
        or a
        jr z,.cpu_stun
        ld a,24
        ld (0xc73b),a
.cpu_stun:
        ld a,(0xc713)
        or a
        jr z,.cpu_move
        xor a
        ld (0xc73f),a
        ld a,(0xc713)
        dec a
        ld (0xc713),a
        jp .draw
.cpu_move:
        ld a,(0xc730)
        or a
        jr z,.cpu_racing
        ld hl,(0xc702)
        ld de,0xc775
        call goal_walk
        ld (0xc702),hl
        jp .draw
.cpu_racing:
        ld a,(0xc757)
        or a
        jr z,.cpu_water_rate
        ld a,(0xc715)
        ld (0xc751),a
        cp 56
        jr nc,.cpu_wade_right
        cp 2
        jr c,.cpu_wade_update
        dec a
        dec a
        jr .cpu_wade_store
.cpu_wade_right:
        ; Stop before the bridge posts at the right edge of the arcade map.
        cp 80
        jr nc,.cpu_wade_update
        inc a
        inc a
.cpu_wade_store:
        ld (0xc715),a
.cpu_wade_update:
        ld hl,(0xc702)
        ld a,(0xc757)
        ld b,a
        ld a,(0xc715)
        call check_bridge_surface
        jr nc,.cpu_wade_surface_ok
        ld a,(0xc751)
        ld (0xc715),a
        ld a,(0xc758)
.cpu_wade_surface_ok:
        ld (0xc757),a
.cpu_water_rate:
        ; The CPU's POWER builds up to 2/3 of the gauge (8 of 12), as in MAME.
        ld a,(0xc705)
        and 3
        jr nz,.cpu_power_ready
        ld a,(0xc73f)
        cp 8
        jr nc,.cpu_power_ready
        inc a
        ld (0xc73f),a
.cpu_power_ready:
        call cpu_follow_path
        ; Same rule as the player; the arcade CPU keeps 2/3 of its POWER.
        ld a,(0xc73f)
        ld b,a
        add a,a
        add a,a
        add a,b
        add a,a
        ld b,a
        ld a,(0xc757)
        ld c,a
        ld a,(0xc71b)
        ld e,a
        ld a,(0xc703)
        call water_speed
        ld a,(0xc771)
        or a
        jp nz,.draw
        ld hl,0xc763
        call speed_pixels
        jp z,.draw
.cpu_advance:
        ld hl,(0xc702)
        ld (0xc754),hl
        ld e,a
        ld d,0
        add hl,de
        ld (0xc702),hl
        ld a,(0xc757)
        ld b,a
        ld a,(0xc715)
        call check_bridge_surface
        jr nc,.cpu_surface_ok
        ld hl,(0xc754)
        ld (0xc702),hl
        ld a,(0xc758)
.cpu_surface_ok:
        ld (0xc757),a
.cpu_energy_ready:
        ld a,(0xc757)
        or a
        jp nz,.draw
        ld hl,(0xc702)
        ld a,h
        cp 8
        jr c,.cpu_obstacle_y
        cp 12
        jr c,.cpu_water_obstacle
        jr .cpu_obstacle_y
.cpu_water_obstacle:
        ld a,(0xc715)
        call river_obstacle_collision
        jp nc,.draw
.cpu_water_contact:
        ld a,(0xc71b)
        or a
        jr z,.cpu_water_stun
        call cpu_lose_boat
.cpu_water_stun:
        xor a
        ld (0xc741),a
        ld a,18
        ld (0xc713),a
        jr .draw
.cpu_obstacle_y:
        ld a,(0xc73b)
        or a
        jr nz,.draw
        ld a,(0xc715)
        call hazard_lookup
        or a
        jr nz,.cpu_contact
        ld (0xc745),a
        jr .draw
.cpu_contact:
        ld b,a
        ld a,(0xc745)
        or a
        jr nz,.draw
        ld a,1
        ld (0xc745),a
        ld a,b
        cp 2
        ld a,0
        jr nz,.cpu_hit_kind
        inc a
.cpu_hit_kind:
        ld (0xc741),a
        ld a,30
        ld (0xc713),a
.draw:
        call finish_tick
        call boat_tick
        call runner_contact
        ; Clear only what the two 120x184 lane copies leave uncovered: the
        ; separator, the right margin and the HUD band (the full-page clear
        ; was the costliest command of the frame).
        ld hl,clear_separator
        call clear_area
        ld hl,clear_margin
        call clear_area
        ld hl,clear_hud
        call clear_area
        xor a
        ld (0xc706),a
        call lane
        ld a,1
        ld (0xc706),a
        call lane
        call draw_clock
        call draw_score
        call draw_power
        call draw_result
        call wait_cmd
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
        ld a,(0xc704)
        out (0x63),a
        xor 1
        ld (0xc704),a
        ei
        ld a,8
        out (0x64),a
        ld a,0xc2
        out (0x63),a
        ; Let the new page reach the screen before the old one is redrawn.
.shown:
        in a,(0x65)
        bit 6,a
        jr nz,.shown
        jp loop

lane:
        ld a,(0xc706)
        or a
        ld hl,(0xc700)
        jr z,.owner
        ld hl,(0xc702)
.owner:
        ; At the goal the arcade camera stops with the line in view and the
        ; runner walks on up the screen.
        push hl
        ld de,3330
        or a
        sbc hl,de
        pop hl
        jr c,.camera_ready
        ld hl,3330
.camera_ready:
        ld (0xc708),hl
        ; Arcade course (tools/build_ironman_course.py). The window shows
        ; world rows P..P+183; world 0..2047 is at VRAM x=0 and 2048..4095
        ; at x=128, both from y=1536 with the world growing upwards, so the
        ; window top is VRAM y = 1536 + ((1864 - P) & 2047).
        ex de,hl
        ld hl,1864
        or a
        sbc hl,de
        ld a,l
        ld (0xc70a),a
        ld a,h
        and 7
        add a,6
        ld (0xc717),a
        ld a,184
        ld (0xc70b),a
        ld a,d
        cp 8
        ld a,128
        jr nc,.source_x
        bit 7,h
        ld a,0
        jr z,.source_x
        ; P=1865..2047: the top P-1864 rows come from the upper half, the
        ; rest from world 2047 down at x=0, y=1536.
        ld a,e
        sub 0x48
        ld (0xc70b),a
        ld a,128
.source_x:
        ld (0xc742),a
        ld hl,bg_template
        call copy_command
        ld a,(0xc742)
        ld (0xc300),a
        ld a,(0xc70a)
        ld (0xc302),a
        ld a,(0xc717)
        ld (0xc303),a
        ld a,(0xc706)
        or a
        ld a,0
        jr z,.bg_x
        ld a,128
.bg_x:
        ld (0xc304),a
        ld a,(0xc704)
        ld (0xc307),a
        ld a,(0xc70b)
        ld (0xc30a),a
        ld hl,0xc300
        call command
        ld a,(0xc70b)
        cp 184
        jr z,.runners
        ld b,a
        ld a,184
        sub b
        ld (0xc30a),a
        ld a,b
        ld (0xc306),a
        xor a
        ld (0xc300),a
        ld (0xc302),a
        ld a,6
        ld (0xc303),a
        ld hl,0xc300
        call command
.runners:
        ; Shores, river rocks and the goal belong to the course image.
        call draw_logs
        call draw_free_boats
        call draw_mine_dots
        xor a
        ld (0xc70c),a
        call runner
        ld a,1
        ld (0xc70c),a
        call runner
        ret

runner:
        ld a,(0xc70c)
        or a
        ld de,(0xc700)
        jr z,.project
        ld de,(0xc702)
.project:
        ld hl,(0xc708)
        call step3_project_y
        ret c
        cp 169
        ret nc
        ld (0xc70d),a
        ld a,(0xc70c)
        or a
        ld a,(0xc70f)
        jr z,.jump_height
        ld a,(0xc73b)
.jump_height:
        or a
        jr z,.project_done
        ld e,a
        ld d,0
        ld hl,jump_arc
        add hl,de
        ld a,(0xc70d)
        sub (hl)
        ret c
        ld (0xc70d),a
.project_done:
        ; Keep the old foot position while using the taller actor frames.
        ld a,(0xc70d)
        sub 16
        ret c
        ld (0xc70d),a
        ld hl,actor_template
        call copy_command
        ld a,(0xc70c)
        or a
        ld a,0
        jr z,.sprite_x
        ld a,16
.sprite_x:
        ld b,a
        ld a,(0xc70c)
        or a
        ld a,(0xc712)
        jr z,.fall_pose
        ld a,(0xc713)
.fall_pose:
        or a
        ld a,b
        jr z,.pose_ready
        add a,32
.pose_ready:
        ld b,a
        ld a,(0xc70c)
        or a
        ld a,(0xc701)
        jr z,.water_pose_check
        ld a,(0xc703)
.water_pose_check:
        cp 8
        ld a,b
        jr c,.pose_final
        ld a,(0xc70c)
        or a
        ld a,(0xc701)
        jr z,.water_pose_end
        ld a,(0xc703)
.water_pose_end:
        cp 12
        ld a,b
        jr nc,.pose_final
        ld a,(0xc70c)
        or a
        ld a,(0xc71a)
        jr z,.boat_pose
        ld a,(0xc71b)
.boat_pose:
        or a
        ld a,b
        jr z,.swim_pose
        and 16
        add a,96
        jr .pose_final
.swim_pose:
        and 16
        add a,64
.pose_final:
        add a,a
        ld (0xc300),a
        ; Alternate the diagnostic limb positions for active runners.
        ld a,(0xc70c)
        or a
        ld a,(0xc712)
        jr z,.animation_stun
        ld a,(0xc713)
.animation_stun:
        or a
        jp nz,.animation_ready
        ld a,(0xc70c)
        or a
        ld a,(0xc756)
        jr z,.wade_state
        ld a,(0xc757)
.wade_state:
        or a
        jr z,.not_wading
        ld a,(0xc705)
        and 8
        add a,a
        add a,a
        ld b,a
        ld a,(0xc70c)
        or a
        ld a,b
        jr z,.wade_x
        add a,64
.wade_x:
        ld (0xc300),a
        ld a,48
        ld (0xc302),a
        ld a,3
        ld (0xc303),a
        ld a,16
        ld (0xc30a),a
        jp .animation_ready
.not_wading:
        ld a,(0xc70c)
        or a
        jr nz,.cpu_animation
        ld a,(0xc746)
        cp 3
        jr c,.check_run_power
        cp 8
        jr nc,.check_run_power
        ld a,(0xc701)
        cp 8
        jr c,.animation_phase
        cp 12
        jr nc,.animation_phase
.check_run_power:
        ld a,(0xc710)
        or a
        jr nz,.animation_phase
        ld a,(0xc70f)
        or a
        jp z,.standing_pose
        jr .animation_phase
.cpu_animation:
        ld a,(0xc730)
        or a
        jp nz,.standing_pose
.animation_phase:
        ; Four anchored arcade running poses on land; water keeps two frames.
        ld a,(0xc70c)
        or a
        ld a,(0xc701)
        jr z,.animation_surface
        ld a,(0xc703)
.animation_surface:
        cp 8
        jr c,.land_animation
        cp 12
        jr c,.two_frame_animation
.land_animation:
        ld a,(0xc70c)
        or a
        jr nz,.forward_animation
        ld a,(0xc746)
        cp 3
        jr z,.face_right
        cp 7
        jr z,.face_left
        cp 4
        jr c,.forward_animation
        cp 7
        jr c,.face_down
        jr .forward_animation
.face_left:
        ld b,0
        jr .direction_frame
.face_right:
        ld b,64
        jr .direction_frame
.face_down:
        ; Four phases, including mirrored poses, alternate the planted leg.
        ld a,(0xc705)
        and 24
        add a,a
        add a,a
        add a,128
        ld (0xc300),a
        ld a,96
        ld (0xc302),a
        jr .animation_ready
.direction_frame:
        ld a,(0xc705)
        and 8
        ld a,b
        jr z,.direction_x
        add a,32
.direction_x:
        ld (0xc300),a
        ld a,96
        ld (0xc302),a
        jr .animation_ready
.forward_animation:
        ld a,(0xc705)
        add a,a
        and 24
        cp 16
        jr c,.land_first_pair
        ld b,a
        ld a,64
        ld (0xc302),a
        ld a,b
        cp 24
        ld a,64
        jr nz,.extra_frame_x
        ld a,128
.extra_frame_x:
        ld b,a
        ld a,(0xc70c)
        or a
        ld a,b
        jr z,.extra_frame_ready
        add a,32
.extra_frame_ready:
        ld (0xc300),a
        jr .animation_ready
.land_first_pair:
        or a
        jr z,.animation_ready
        ld a,32
        ld (0xc302),a
        jr .animation_ready
.two_frame_animation:
        ld a,(0xc705)
        and 8
        jr z,.animation_ready
        ld a,32
        ld (0xc302),a
        jr .animation_ready
.standing_pose:
        ; Standing is a separate, two-legged arcade pose in atlas row 64.
        ; Water poses stay in their swimming/rowing frame.
        ld a,(0xc70c)
        or a
        ld a,(0xc701)
        jr z,.standing_surface
        ld a,(0xc703)
.standing_surface:
        cp 8
        jr c,.set_standing
        cp 12
        jr c,.animation_ready
.set_standing:
        ld a,64
        ld (0xc302),a
.animation_ready:
        ld a,(0xc706)
        or a
        ld a,0
        jr z,.lane_x
        ld a,128
.lane_x:
        ld b,a
        ld a,(0xc70c)
        or a
        ld a,(0xc714)
        jr z,.add_lane_x
        ld a,(0xc715)
.add_lane_x:
        add a,b
.set_x:
        sub 4
        ld (0xc304),a
        ld a,(0xc70d)
        ld (0xc306),a
        ld a,(0xc704)
        ld (0xc307),a
        call actor_command
        ; The explosion is drawn over the runner.
        jp draw_mine_blast
; Draw captured debris briefly behind a runner after a mine collision.
draw_mine_blast:
        ld a,(0xc70c)
        or a
        ld a,(0xc740)
        jr z,.kind_ready
        ld a,(0xc741)
.kind_ready:
        or a
        ret z
        ld a,(0xc70c)
        or a
        ld a,(0xc712)
        jr z,.timer_ready
        ld a,(0xc713)
.timer_ready:
        ; Arcade explosion: ten frames over the first 20 updates of the fall
        ; (timer 30 down to 11), objects atlas at y=1024.
        cp 11
        ret c
        ld b,a
        ld a,30
        sub b
        srl a
        ld b,a
        push bc
        ld hl,sprite_template
        call copy_command
        pop bc
        ld a,b
        and 3
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        add a,128
        ld (0xc300),a
        ld a,b
        and 12
        add a,a
        add a,a
        ld (0xc302),a
        ld a,4
        ld (0xc303),a
        ld a,32
        ld (0xc308),a
        ld a,16
        ld (0xc30a),a
        ld a,(0xc706)
        or a
        ld a,0
        jr z,.lane_x
        ld a,128
.lane_x:
        ld b,a
        ld a,(0xc70c)
        or a
        ld a,(0xc714)
        jr z,.runner_x
        ld a,(0xc715)
.runner_x:
        add a,b
        sub 4
        ld (0xc304),a
        ld a,(0xc70d)
        add a,12
        ld (0xc306),a
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        jp command

; A close pass knocks down the trailing runner. A cooldown prevents repeats.
runner_contact:
        ; No contact once a runner has reached the goal (arcade).
        ld a,(0xc72f)
        ld b,a
        ld a,(0xc730)
        or b
        ret nz
        ld a,(0xc716)
        or a
        jr z,.check_contact
        dec a
        ld (0xc716),a
        ret
.check_contact:
        ld a,(0xc712)
        ld b,a
        ld a,(0xc713)
        or b
        ret nz
        call boat_knock
        ret c
        ld a,(0xc70f)
        or a
        ret nz
        ld a,(0xc714)
        ld b,a
        ld a,(0xc715)
        sub b
        add a,16
        cp 33
        ret nc
        ld hl,(0xc700)
        ld de,(0xc702)
        or a
        sbc hl,de
        jr z,.no_contact
        jr c,.player_behind
        ld a,h
        or a
        ret nz
        ld a,l
        cp 12
        ret nc
        ld a,30
        ld (0xc713),a
        xor a
        ld (0xc741),a
        call cpu_release_boat
        jr .contact_done
.player_behind:
        ld a,h
        cp 0xff
        ret nz
        ld a,l
        cp 245
        ret c
        ld a,30
        ld (0xc712),a
        xor a
        ld (0xc740),a
        call player_release_boat
        xor a
        ld (0xc710),a
.contact_done:
        ld a,45
        ld (0xc716),a
.no_contact:
        ret
; In the river, a swimmer who touches the other runner's boat throws him
; into the water, whoever is ahead (arcade); the boat is left free.
; Carry when it happened.
boat_knock:
        ld a,(0xc71a)
        or a
        jr z,.cpu_boat
        ld a,(0xc71b)
        or a
        ret nz
        ld a,(0xc703)
        call .in_river
        ret nc
        call .near
        ret nc
        call player_release_boat
        ld a,30
        ld (0xc712),a
        xor a
        ld (0xc740),a
        ld (0xc710),a
        jr .done
.cpu_boat:
        ld a,(0xc71b)
        or a
        ret z
        ld a,(0xc701)
        call .in_river
        ret nc
        call .near
        ret nc
        call cpu_release_boat
        ld a,30
        ld (0xc713),a
        xor a
        ld (0xc741),a
.done:
        ld a,45
        ld (0xc716),a
        scf
        ret
; Carry when A (progress high byte) is in the river.
.in_river:
        cp 8
        ccf
        ret nc
        cp 12
        ret
; Carry when the runners are within 20 pixels sideways and 32 along.
.near:
        ld a,(0xc714)
        ld b,a
        ld a,(0xc715)
        sub b
        add a,20
        cp 41
        ret nc
        ld hl,(0xc700)
        ld de,(0xc702)
        or a
        sbc hl,de
        ld de,32
        add hl,de
        ld a,h
        or a
        jr nz,.far
        ld a,l
        cp 65
        ret
.far:
        or a
        ret

; End the diagnostic course after the river, retaining the first finisher.
finish_tick:
        ld a,(0xc735)
        or a
        ret nz
        ld a,(0xc701)
        cp 13
        jr c,.cpu_finish
        ld a,(0xc72f)
        or a
        jr nz,.cpu_finish
        ld a,1
        ld (0xc72f),a
        ; Stop the running cycle once the player has crossed the finish.
        xor a
        ld (0xc710),a
        ld (0xc70f),a
        ld (0xc712),a
        ld (0xc746),a
        ld (0xc756),a
        ; The runner keeps running past the line (goal_walk).
        ld a,8
        ld (0xc710),a
        ; Record the provisional bonus bracket from remaining whole seconds.
        ld a,(0xc731)
        srl a
        cp 5
        jr c,.bonus_ready
        ld a,5
.bonus_ready:
        ld (0xc736),a
        add a,a
        ld e,a
        ld d,0
        ld hl,bonus_points
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (0xc739),de
        ld a,(0xc72e)
        or a
        jr nz,.cpu_finish
        ld a,1
        ld (0xc72e),a
.cpu_finish:
        ld a,(0xc703)
        cp 13
        ret c
        ld a,1
        ld (0xc730),a
        ld a,(0xc72e)
        or a
        ret nz
        ld a,2
        ld (0xc72e),a
        ret

draw_result:
        ld a,(0xc735)
        or a
        jr nz,.time_up
        ; At the goal, as in the arcade: PLAYER 1 / (NICK), YOU MADE IT once
        ; the arm is raised; CPU (JOE) / GOAL in the CPU's lane.
        ld a,(0xc72f)
        or a
        jr z,.cpu_label
        ld a,(0xc701)
        cp 13
        jr c,.cpu_label
        ld hl,label_player
        call label_blit
        ld hl,label_nick
        call label_blit
        ld a,(0xc774)
        cp 106
        jr c,.cpu_label
        ld hl,label_made_it
        call label_blit
.cpu_label:
        ld a,(0xc730)
        or a
        ret z
        ld a,(0xc703)
        cp 13
        ret c
        ld hl,label_cpu
        call label_blit
        ld hl,label_goal
        jp label_blit
.time_up:
        ; Lost by the clock (arcade): PLAYER 1 / (NICK), YOU BLEW IT in red
        ; (C72E = 3: TIME UP for the player).
        ld a,(0xc72e)
        cp 3
        jr nz,.time_up_label
        ld hl,label_player_lost
        call label_blit
        ld hl,label_nick_lost
        call label_blit
        ld hl,label_blew_it
        call label_blit
.time_up_label:
        ld a,(0xc72e)
        or a
        ret z
        ld b,a
        ld hl,result_template
        push bc
        call copy_command
        pop bc
        ld a,b
        cp 3
        jr nz,.check_cpu_label
        ld a,96
        ld (0xc300),a
        ld a,16
        ld (0xc302),a
        jr .label_ready
.check_cpu_label:
        cp 2
        jr nz,.label_ready
        ld a,8
        ld (0xc302),a
.label_ready:
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        jp command

; A fresh run-button press after finishing resets the standalone experiment.
result_input:
        ld a,(0xc72f)
        or a
        ret z
        xor a
        call 0x00d8
        or a
        jr nz,.pressed
        ld a,1
        call 0x00d8
        or a
        jr nz,.pressed
        ld a,1
        ld (0xc738),a
        ret
.pressed:
        ld a,(0xc738)
        or a
        ret z
        jp reset_race

draw_bonus:
        ld a,(0xc735)
        or a
        ret nz
        ld a,(0xc72f)
        or a
        ret z
        ld hl,bonus_label_template
        call copy_command
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld hl,clock_template
        call copy_command
        ld a,(0xc736)
        add a,a
        add a,a
        add a,a
        ld (0xc300),a
        ld a,66
        ld (0xc304),a
        ld a,24
        ld (0xc306),a
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld hl,bonus_sec_template
        call copy_command
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        jp command
bonus_points:
        dw 0,1000,2000,4000,6000,8000
jump_arc:
        db 0,2,4,6,8,10,12,14,15,16,17,18,18
        db 18,17,16,15,14,12,10,8,6,4,2,0

; BIOS JIFFY supplies 50 or 60 ticks per second independently of rendering.
race_clock:
        ld a,(0xc735)
        or a
        ret nz
        ld a,(0xc72f)
        or a
        ret nz
        ld hl,(0xfc9e)
        ld de,(0xc732)
        or a
        sbc hl,de
        ld a,h
        or a
        jr nz,.elapsed
        ld a,(0xc734)
        cp l
        jr c,.elapsed
        jr z,.elapsed
        ret
.elapsed:
        ld hl,(0xc732)
        ld a,(0xc734)
        ld e,a
        ld d,0
        add hl,de
        ld (0xc732),hl
        ld a,(0xc731)
        or a
        ret z
        dec a
        ld (0xc731),a
        call psg_countdown      ; the last seconds and the end (Spectrum)
        ret nz
        ld a,1
        ld (0xc735),a
        ld (0xc72f),a
        ld (0xc730),a
        ld a,3
        ld (0xc72e),a
        ret

; Arcade clock 0:SS.t at the top of the player's lane.
draw_clock:
        ld a,(0xc72f)
        or a
        jr nz,.show
        ; Tenths left in this second, from the BIOS clock (rate/10 per tenth).
        ld hl,(0xfc9e)
        ld de,(0xc732)
        or a
        sbc hl,de
        ld a,(0xc734)
        cp 50
        ld c,5
        jr z,.rate
        ld c,6
.rate:
        ld a,l
        ld b,0
.divide:
        cp c
        jr c,.divided
        sub c
        inc b
        jr .divide
.divided:
        ld a,9
        sub b
        jr nc,.tenths
        xor a
.tenths:
        ld (0xc776),a
.show:
        xor a
        ld d,48
        call clock_digit
        ld hl,label_colon
        call label_blit
        ld a,(0xc731)
        ld b,0
.tens:
        cp 10
        jr c,.digits
        sub 10
        inc b
        jr .tens
.digits:
        ld (0xc737),a
        ld a,b
        ld d,64
        call clock_digit
        ld a,(0xc737)
        ld d,72
        call clock_digit
        ld hl,label_dot
        call label_blit
        ld a,(0xc776)
        ld d,88
clock_digit:
        ld c,0                  ; the clock row
; A = digit, D = x, C = y.
digit_at:
        add a,a
        add a,a
        add a,a
        push de
        push bc                 ; the LDIs of copy_command change BC
        push af
        ld hl,clock_template
        call copy_command
        pop af
        pop bc
        pop de
        ld (0xc300),a
        ld a,d
        ld (0xc304),a
        ld a,c
        ld (0xc306),a
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        jp command

; Arcade: 10 points per stride (about 4800 over the course). Here 10 for
; each multiple of 8 rows passed going forward. HL = new progress, C752 =
; previous; HL is preserved.
stride_points:
        push hl
        ld de,(0xc752)
        ld b,3
.eighths:
        srl h
        rr l
        srl d
        rr e
        djnz .eighths
        or a
        sbc hl,de
        ld b,l
        inc b
        jr .next
.add:
        ld de,10
        call add_score
.next:
        djnz .add
        pop hl
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

; Single game score in the player's lane, under the clock (as the arcade
; puts both on player 1's side): red 1P at x 24, y 12 and the total
; left-aligned from x 48, under the clock digits (leading zeros hidden).
SCORE_ROW equ 12
draw_score:
        ld hl,label_1p
        call label_blit
        ld hl,(0xc75c)
        ld a,(0xc75e)
        ld e,a                  ; E:HL = score
        ld ix,score_powers
        ld d,48
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
        ld a,b
        ld c,SCORE_ROW
        call digit_at
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
        ld a,l
        ld c,SCORE_ROW
        jp digit_at
score_powers:
        db 0xa0,0x86,0x01, 0x10,0x27,0x00, 0xe8,0x03,0x00
        db 0x64,0x00,0x00, 0x0a,0x00,0x00, 0

; POWER gauges occupy the lower HUD area outside both course viewports.
draw_power:
        xor a
        ld (0xc73d),a
        call .one
        ld a,1
        ld (0xc73d),a
        ; Continue with the CPU gauge.
.one:
        ld a,(0xc73d)
        or a
        ld a,(0xc710)
        jr z,.energy_ready
        ld a,(0xc713)
        or a
        ld a,0
        jr nz,.energy_ready
        ld a,(0xc73f)
.energy_ready:
        ld b,a
        add a,a
        add a,a
        add a,b
        ld (0xc73e),a
        ld hl,power_label_template
        call copy_command
        ld a,(0xc73d)
        or a
        ld a,3
        jr z,.label_x
        ld a,131
.label_x:
        ld (0xc304),a
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld hl,power_bg_template
        call copy_command
        ld a,(0xc73d)
        or a
        ld a,42
        jr z,.bar_x
        ld a,170
.bar_x:
        ld (0xc304),a
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        call command
        ld a,(0xc73e)
        or a
        ret z
        ld (0xc308),a
        ld a,0xdd
        ld (0xc310),a
        ld (0xc311),a
        ld hl,0xc300
        jp command

        include "../build/step3/visual-river-layout.inc"

; HL=runner progress, A=runner X. Carry indicates a rock or log hit.
river_obstacle_collision:
        ld (0xc74b),a
        ld (0xc74c),hl
        push ix
        ; River rocks belong to the arcade course: rock cells (3) of the
        ; shared collision table.
        call land_collision_lookup
        cp 3
        jr z,.hit
        ld ix,log_positions
        ld b,3
.log_loop:
        ld e,(ix+0)
        ld d,(ix+1)
        call .near_progress
        jr nc,.log_next
        push bc
        ld b,(ix+2)
        call log_x
        ld b,a
        ; Overlap when runner X + 44 - (log X + 32) is below 40.
        ld a,(0xc74b)
        add a,44
        sub b
        pop bc
        cp 40
        jr c,.hit
.log_next:
        inc ix
        inc ix
        inc ix
        djnz .log_loop
        pop ix
        or a
        ret
.hit:
        pop ix
        scf
        ret
.near_progress:
        ld hl,(0xc74c)
        or a
        sbc hl,de
        ld a,h
        or a
        jr z,.positive
        cp 255
        jr nz,.far
        ld a,l
        cp 246
        jr c,.far
        scf
        ret
.positive:
        ld a,l
        cp 11
        jr nc,.far
        scf
        ret
.far:
        or a
        ret

; Two moving logs at each of four fixed positions in the shared river.
draw_logs:
        ld ix,log_positions
        ld b,3
.next:
        push bc
        ld e,(ix+0)
        ld d,(ix+1)
        ld hl,(0xc708)
        call step3_project_y
        jr c,.advance
        cp 153
        jr nc,.advance
        ld (0xc729),a
        ld b,(ix+2)
        call log_x
        ld (0xc72e),a
        ld hl,sprite_template
        call copy_command
        ; Arcade frames 144/148 alternate; objects atlas at y=1024.
        ld a,(0xc705)
        and 4
        add a,a
        add a,a
        add a,a
        add a,64
        ld (0xc300),a
        xor a
        ld (0xc302),a
        ld a,4
        ld (0xc303),a
        ld a,32
        ld (0xc308),a
        ld (0xc30a),a
        ; Clip at the lane edges: A is the log's x+32. Nothing is visible at
        ; A=0, and a zero width would make the V9990 copy a whole atlas row.
        ld a,(0xc72e)
        or a
        jp z,.advance
        cp 32
        jr nc,.right_part
        ld b,a
        ld a,32
        sub b
        ld c,a
        ld a,(0xc300)
        add a,c
        ld (0xc300),a
        ld a,b
        ld (0xc308),a
        xor a
        jr .x_ready
.right_part:
        sub 32
        cp 89
        jr c,.x_ready
        ld b,a
        ld a,120
        sub b
        ld (0xc308),a
        ld a,b
.x_ready:
        ld b,a
        ld a,(0xc706)
        or a
        ld a,b
        jr z,.log_lane
        add a,128
.log_lane:
        ld (0xc304),a
        ld a,(0xc729)
        ld (0xc306),a
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        call command
.advance:
        inc ix
        inc ix
        inc ix
        pop bc
        dec b
        jp nz,.next
        ret

; B = phase. Returns A = (C72A + phase) mod 152, i.e. the log's x + 32.
log_x:
        ld a,(0xc72a)
        add a,b
        jr c,.wrap
        cp 152
        ret c
.wrap:
        sub 152
        ret

; Like land_collision_lookup, but vegetation (4) is not a hazard: it only
; stops the runner (check_bridge_surface), it does not trip or get jumped.
hazard_lookup:
        call land_collision_lookup
        cp 4
        ret nz
        xor a
        ret

; The CPU follows the open ground like the arcade's: when vegetation lies
; 8, 24 or 40 pixels ahead it moves 2 pixels towards the nearest X, 8 to 48
; pixels to either side, that is clear at all three distances.
cpu_follow_path:
        ld a,(0xc715)
        call cpu_clear_at
        ret z
        ld c,8
.search:
        ld a,(0xc715)
        sub c
        jr c,.try_right
        push bc
        call cpu_clear_at
        pop bc
        jr z,.go_left
.try_right:
        ld a,(0xc715)
        add a,c
        cp 97
        jr nc,.wider
        push bc
        call cpu_clear_at
        pop bc
        jr z,.go_right
.wider:
        ld a,c
        add a,8
        ld c,a
        cp 56
        jr c,.search
        ret
.go_left:
        ld a,(0xc715)
        sub 2
        ld (0xc715),a
        ret
.go_right:
        ld a,(0xc715)
        add a,2
        ld (0xc715),a
        ret

; A = X. Z when no vegetation lies 8, 24 or 40 pixels ahead of the CPU.
cpu_clear_at:
        ld (0xc75f),a
        ld de,8
.ahead:
        ld hl,(0xc702)
        add hl,de
        ld a,(0xc75f)
        push de
        call land_collision_lookup
        pop de
        cp 4
        jr z,.blocked
        ld a,e
        add a,16
        ld e,a
        cp 41
        jr c,.ahead
        xor a
        ret
.blocked:
        or a
        ret

; B = speed (1/16 px per update), C = wading flag, E = boat flag, A = high
; byte of the progress. Returns B scaled as measured in MAME: wading 1/2,
; swimming 3/8 (55 px/s for the CPU), a boat 11/16 (100 px/s).
water_speed:
        ld d,a
        ld a,c
        or a
        jr z,.not_wading
        srl b
        ret
.not_wading:
        ld a,d
        cp 8
        ret c
        cp 12
        ret nc
        ld a,e
        or a
        jr nz,.boat
        ld a,b
        srl a
        srl a
        ld c,a
        srl a
        add a,c
        ld b,a
        ret
.boat:
        ld a,b
        srl a
        ld c,a
        srl a
        srl a
        add a,c
        ld c,a
        ld a,b
        srl a
        srl a
        srl a
        srl a
        add a,c
        ld b,a
        ret

; HL = fractional accumulator, B = speed in 1/16 px per update at 30 updates
; per second (two BIOS ticks). Scaled by the ticks since the previous update
; (C777). Returns A = whole pixels for this update, Z when there are none.
speed_pixels:
        push hl
        ld a,(0xc777)
        ld c,a
        ld h,0
        ld l,b
        ld d,h
        ld e,l
        dec c
        jr z,.scaled
.multiply:
        add hl,de
        dec c
        jr nz,.multiply
.scaled:
        ; Per tick: half the per-update speed at 60 Hz; at 50 Hz x0.59375
        ; (1/2 + 1/16 + 1/32), so the pace in pixels per second is the same.
        srl h
        rr l
        ld a,(0xc734)
        cp 50
        jr nz,.rate_done
        push hl
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        ld d,h
        ld e,l
        srl d
        rr e
        add hl,de
        ex de,hl
        pop hl
        add hl,de
.rate_done:
        pop de
        ld a,(de)
        add a,l
        ld l,a
        jr nc,.carry_done
        inc h
.carry_done:
        and 15
        ld (de),a
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        ld a,l
        or a
        ret

; Look up the shared land map in ROM bank 23. Each byte describes an
; 8x8 world cell; preserve progress for the caller.
land_collision_lookup:
        push hl
        add a,8
        srl a
        srl a
        srl a
        ld c,a
        ld b,0
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,bc
        ld bc,0x8000
        add hl,bc
        ld a,23
        ld (0x7000),a
        ld a,(hl)
        pop hl
        ret

land_surface_lookup:
        push hl
        add a,8
        srl a
        srl a
        srl a
        ld c,a
        ld b,0
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,bc
        ld bc,0xa000
        add hl,bc
        ld a,23
        ld (0x7000),a
        ld a,(hl)
        pop hl
        ret

; HL=world position, A=runner X, B=old wading flag. Returns A=new flag;
; carry means the water-to-deck move must be rejected.
check_bridge_surface:
        ld (0xc75a),a
        ld a,b
        ld (0xc758),a
        ; Vegetation stops the runner, as in the arcade.
        ld a,(0xc75a)
        call land_collision_lookup
        cp 4
        jr nz,.not_bush
        scf
        ret
.not_bush:
        ld a,h
        cp 8
        jr nc,.dry
        ld a,(0xc75a)
        call land_surface_lookup
        cp 2
        jr nz,.not_deck
        ld a,(0xc758)
        or a
        jr z,.dry
        ld a,1
        scf
        ret
.not_deck:
        cp 1
        jr z,.water
.dry:
        xor a
        ret
.water:
        ld a,1
        or a
        ret

; Carry when a swimmer/boat overlaps either moving log horizontally.
log_collision_x:
        ld b,a
        ld a,(0xc72a)
        sub b
        add a,16
        cp 33
        jr c,.yes
        ld a,(0xc72b)
        sub b
        add a,12
        cp 25
        jr c,.yes
        or a
        ret
.yes:
        scf
        ret
; Carry when X intersects one of the two diagnostic log lanes.
obstacle_x:
        cp 23
        jr c,.no
        cp 48
        jr c,.yes
        cp 63
        jr c,.no
        cp 88
        jr nc,.no
.yes:
        scf
        ret
.no:
        or a
        ret

; Each boat stores status (0 free, 1 player, 2 CPU, 3 lost), X and Y.
boat_tick:
        ld hl,0xc770
        call .countdown
        inc hl
        call .countdown
        call boats_approach
        jr .pick
.countdown:
        ld a,(hl)
        or a
        ret z
        dec (hl)
        ret
.pick:
        ld a,(0xc71a)
        or a
        jr z,.player_pick
        ld hl,(0xc700)
        ld a,(0xc714)
        ld c,1
        call boat_follow
        jr .cpu_pick
.player_pick:
        ld a,(0xc712)
        or a
        jr nz,.cpu_pick
        ld hl,(0xc700)
        ld a,(0xc714)
        ld c,1
        call boat_pick
.cpu_pick:
        ld a,(0xc71b)
        or a
        jr z,.cpu_try
        ld hl,(0xc702)
        ld a,(0xc715)
        ld c,2
        jp boat_follow
.cpu_try:
        ld a,(0xc713)
        or a
        ret nz
        ld hl,(0xc702)
        ld a,(0xc715)
        ld c,2
        jp boat_pick

; Parameters: HL world progress, A x, C runner number (1 or 2).
boat_pick:
        ld (0xc723),hl
        ld (0xc725),a
        ld a,c
        ld (0xc726),a
        ld a,h
        cp 8
        ret c
        cp 12
        ret nc
        xor a
        ld (0xc727),a
.candidate:
        ld a,(0xc727)
        ld e,a
        ld d,0
        ld hl,0xc718
        add hl,de
        ld a,(hl)
        or a
        jr nz,.next
        ld hl,0xc71c
        add hl,de
        ld a,(0xc725)
        sub (hl)
        add a,8
        cp 17
        jr nc,.next
        sla e
        ld hl,0xc71e
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,(0xc723)
        or a
        sbc hl,de
        ld a,h
        or a
        jr z,.positive
        cp 0xff
        jr nz,.next
        ld a,l
        cp 248
        jr c,.next
        jr .take
.positive:
        ld a,l
        cp 9
        jr nc,.next
.take:
        ; Climbing aboard takes 25 updates (arcade: five poses, 0.8 s).
        ld a,(0xc726)
        dec a
        ld e,a
        ld d,0
        ld hl,0xc770
        add hl,de
        ld (hl),25
        ld a,(0xc727)
        ld e,a
        ld d,0
        ld hl,0xc718
        add hl,de
        ld a,(0xc726)
        ld (hl),a
        ld hl,0xc71a
        dec a
        ld e,a
        add hl,de
        ld a,(0xc727)
        inc a
        ld (hl),a
        ret
.next:
        ld a,(0xc727)
        inc a
        ld (0xc727),a
        cp 2
        jr c,.candidate
        ret

boat_follow:
        ld (0xc723),hl
        ld (0xc725),a
        ld a,h
        cp 8
        jr c,.release
        cp 12
        jr nc,.release
        ld a,c
        dec a
        ld e,a
        ld d,0
        ld hl,0xc71a
        add hl,de
        ld a,(hl)
        dec a
        ld e,a
        ld hl,0xc71c
        add hl,de
        ld a,(0xc725)
        ld (hl),a
        sla e
        ld hl,0xc71e
        add hl,de
        ld de,(0xc723)
        ld (hl),e
        inc hl
        ld (hl),d
        ret
.release:
        ld a,c
        cp 1
        jp z,player_lose_boat
        jp cpu_lose_boat

player_release_boat:
        ld hl,0xc71a
        xor a
        jr boat_release
cpu_release_boat:
        ld hl,0xc71b
        xor a
        jr boat_release
player_lose_boat:
        ld hl,0xc71a
        ld a,3
        jr boat_release
cpu_lose_boat:
        ld hl,0xc71b
        ld a,3
boat_release:
        ld b,a
        ld a,(hl)
        or a
        ret z
        ld (hl),0
        dec a
        ld e,a
        ld d,0
        ld hl,0xc718
        add hl,de
        ld (hl),b
        ret

draw_free_boats:
        xor a
        ld (0xc727),a
.next:
        ld a,(0xc727)
        ld e,a
        ld d,0
        ld hl,0xc718
        add hl,de
        ld a,(hl)
        or a
        jp nz,.advance
        ld hl,0xc71c
        add hl,de
        ld a,(hl)
        ld (0xc728),a
        sla e
        ld hl,0xc71e
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,(0xc708)
        call step3_project_y
        jr c,.advance
        cp 184+32
        jr nc,.advance          ; wholly below the lane
        ; Arcade boat (32x64), centred on the runner's body: top at Y-32.
        sub 32
        ld (0xc729),a
        ld hl,sprite_template
        call copy_command
        ; It rocks by alternating with its mirror about every 12 frames.
        ld a,(0xfc9e)
        and 8
        add a,a
        add a,a
        ld (0xc300),a
        xor a
        ld (0xc302),a
        ld a,4
        ld (0xc303),a
        ld a,32
        ld (0xc308),a
        ld a,64
        ld (0xc30a),a
        ld a,(0xc729)
        ; Above the lane only for Y < 32 (top 224..255). A boat low in the
        ; lane (top 128..183) has bit 7 set too: taken as above, its height
        ; wrapped round and a tall strip of the sprite sheet was copied.
        cp 224
        jr c,.top_ok
        ; Above the lane: skip the hidden rows.
        neg
        ld (0xc302),a
        ld b,a
        ld a,64
        sub b
        ld (0xc30a),a
        xor a
        ld (0xc729),a
.top_ok:
        ld a,(0xc729)
        ld b,a
        ld a,(0xc30a)
        add a,b
        cp 185
        jr c,.height_ok
        ld a,184
        sub b
        ld (0xc30a),a
.height_ok:
        ld a,(0xc706)
        or a
        ld a,0
        jr z,.boat_x
        ld a,128
.boat_x:
        ld b,a
        ld a,(0xc728)
        add a,b
        ld (0xc304),a
        ld a,(0xc729)
        ld (0xc306),a
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        call command
.advance:
        ld a,(0xc727)
        inc a
        ld (0xc727),a
        cp 2
        jp c,.next
        ret

; A free boat comes down the river towards a swimmer without a boat who
; is up to 80 pixels behind it and within 32 pixels sideways (as in MAME),
; one pixel per update, also closing in sideways.
boats_approach:
        ld hl,(0xc700)
        ld a,(0xc71a)
        ld b,a
        ld a,(0xc714)
        call .one_swimmer
        ld hl,(0xc702)
        ld a,(0xc71b)
        ld b,a
        ld a,(0xc715)
.one_swimmer:
        ld (0xc75f),a
        ld a,b
        or a
        ret nz
        ld a,h
        cp 8
        ret c
        cp 12
        ret nc
        ld (0xc76c),hl
        xor a
.boat:
        ld (0xc769),a
        ld e,a
        ld d,0
        ld hl,0xc718
        add hl,de
        ld a,(hl)
        or a
        jr nz,.skip
        ; Sideways distance.
        ld hl,0xc71c
        add hl,de
        ld a,(0xc75f)
        sub (hl)
        add a,32
        cp 65
        jr nc,.skip
        ; Progress distance: boat - swimmer in 1..80.
        sla e
        ld hl,0xc71e
        add hl,de
        push hl
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld de,(0xc76c)
        or a
        sbc hl,de
        pop de
        jr c,.skip
        ld a,h
        or a
        jr nz,.skip
        ld a,l
        or a
        jr z,.skip
        cp 81
        jr nc,.skip
        ; Move down one pixel.
        ex de,hl
        ld a,(hl)
        sub 1
        ld (hl),a
        inc hl
        ld a,(hl)
        sbc a,0
        ld (hl),a
        ; And one pixel sideways towards the swimmer.
        ld a,(0xc769)
        ld e,a
        ld d,0
        ld hl,0xc71c
        add hl,de
        ld a,(0xc75f)
        cp (hl)
        jr z,.skip
        jr c,.left
        inc (hl)
        jr .skip
.left:
        dec (hl)
.skip:
        ld a,(0xc769)
        inc a
        cp 2
        jr c,.boat
        ret

; The pose selection still names a cell of the old 24x32 actor atlas
; (C300 x, C302 row at y=1280). Draw instead the arcade pose: a 32x48 cell
; at y=3584 (row x 3/2) with the feet in place, or for rowing the 48x64
; boat at y=1088 (player x=0/48, CPU x=96/144). Wading (C303=3) keeps its
; frame of the sprite atlas. Clipped at the top and bottom of the lane.
actor_command:
        call goal_pose
        jr nc,.not_goal
        ld a,32
        ld (0xc308),a
        ld a,48
        ld (0xc30a),a
        ld a,(0xc304)
        sub 4
        ld (0xc304),a
        jp .raise
.not_goal:
        ld a,(0xc303)
        cp 3
        jr nz,.not_wading
        ; Waist-deep wading: arcade poses in row 192 (same x as before).
        ld a,0xc0
        ld (0xc302),a
        ld a,0x0e
        ld (0xc303),a
        ; The player's pose follows where he moves, head always up as in the
        ; arcade: back (row 192, x + 128) or sideways (row 288: left x + 64,
        ; right x + 128); tools/build_step3_visual.py draws the cells.
        ld a,(0xc70c)
        or a
        jr nz,.wade_facing
        ld a,(0xc746)
        cp 3
        jr z,.wade_right
        cp 7
        jr z,.wade_left
        cp 4
        jr c,.wade_facing
        cp 7
        jr nc,.wade_facing
        ld a,(0xc300)
        add a,128
        ld (0xc300),a
        jr .wade_facing
.wade_left:
        ld b,64
        jr .wade_side
.wade_right:
        ld b,128
.wade_side:
        ld a,(0xc300)
        add a,b
        ld (0xc300),a
        ld a,0x20               ; row 288: 3584 + 288 = 0x0f20
        ld (0xc302),a
        ld a,0x0f
        ld (0xc303),a
.wade_facing:
        ld a,32
        ld (0xc308),a
        ld a,48
        ld (0xc30a),a
        ld a,(0xc304)
        sub 4
        ld (0xc304),a
        jp .raise
.not_wading:
        ; Boat poses are x >= 192 in rows 0/32; the running-back poses of
        ; row 96 also reach x = 192/224 and stay runner poses.
        ld a,(0xc302)
        cp 96
        jr nc,.runner_pose
        ld a,(0xc300)
        cp 192
        jr nc,.boat
.runner_pose:
        ld a,(0xc302)
        ld b,a
        srl a
        add a,b
        ld (0xc302),a
        ld a,0x0e
        ld (0xc303),a
        ld a,32
        ld (0xc308),a
        ld a,48
        ld (0xc30a),a
        ld a,(0xc304)
        sub 4
        ld (0xc304),a
        jr .raise
.boat:
        sub 192
        ld b,a
        add a,a
        add a,b
        ld b,a
        ld a,(0xc302)
        or a
        ld a,b
        jr z,.boat_frame
        add a,48
.boat_frame:
        ld (0xc300),a
        ld a,0x40
        ld (0xc302),a
        ; While climbing aboard: frame (25-countdown)/5, row 128 or 192.
        ld a,(0xc70c)
        ld e,a
        ld d,0
        ld hl,0xc770
        add hl,de
        ld a,(hl)
        or a
        jr z,.rowing
        ld b,a
        ld a,25
        sub b
        ld c,0
.fifth:
        cp 5
        jr c,.fifth_done
        sub 5
        inc c
        jr .fifth
.fifth_done:
        ld a,c
        add a,a
        ld b,a
        add a,a
        add a,b
        add a,a
        add a,a
        add a,a
        ld (0xc300),a
        ld a,(0xc70c)
        or a
        ld a,0x80
        jr z,.board_row
        ld a,0xc0
.board_row:
        ld (0xc302),a
.rowing:
        ld a,4
        ld (0xc303),a
        ld a,48
        ld (0xc308),a
        ld a,64
        ld (0xc30a),a
        ld a,(0xc304)
        sub 12
        ld (0xc304),a
.raise:
        ld a,(0xc306)
        sub 16
        jr nc,.top_ok
        ; Rows above the lane are skipped; an actor wholly above it is not
        ; drawn (else the height wrapped round and a tall strip of the
        ; sprite sheet was copied: swimmers and boats in a column).
        neg
        ld b,a
        ld a,(0xc30a)
        sub b
        ret c
        ret z
        ld (0xc30a),a
        ld a,(0xc302)
        add a,b
        ld (0xc302),a
        jr nc,.skipped
        ld hl,0xc303
        inc (hl)
.skipped:
        xor a
.top_ok:
        cp 184
        ret nc                  ; wholly below the lane
        ld (0xc306),a
        ld b,a
        ld a,(0xc30a)
        add a,b
        cp 185
        jr c,.draw
        ld a,184
        sub b
        ld (0xc30a),a
.draw:
        ld hl,0xc300
        jp command

; After the line the arcade runner keeps running 80 pixels, then stops
; and the goal timer (DE) counts updates for the goal poses. HL = progress,
; returned updated. Runners stopped elsewhere (time-up, tests) stay put.
goal_walk:
        ld a,(0xc735)
        or a
        ret nz
        ld a,h
        cp 13
        ret c
        push hl
        ld bc,-3408
        add hl,bc
        pop hl
        jr c,.stopped
        inc hl
        inc hl
        inc hl
        inc hl
        ret
.stopped:
        ld a,(de)
        inc a
        ret z
        ld (de),a
        ret

; Carry with the atlas cell in C300/C302/C303 when the runner stands at the
; goal: turning round (16 updates), then panting; the player raises his arm
; after ~3.5 s (frames 136 then 144 of the arcade).
goal_pose:
        ld a,(0xc735)
        or a
        ret nz
        ld a,(0xc70c)
        or a
        jr nz,.cpu
        ld a,(0xc72f)
        ld b,a
        ld a,(0xc774)
        ld c,a
        ld hl,(0xc700)
        jr .check
.cpu:
        ld a,(0xc730)
        ld b,a
        ld a,(0xc775)
        ld c,a
        ld hl,(0xc702)
.check:
        ld a,b
        or a
        ret z
        ld de,-3408
        add hl,de
        ret nc
        ld a,(0xc70c)
        ld e,a
        ld a,c
        cp 8
        ld b,0
        jr c,.turn
        cp 16
        ld b,1
        jr c,.turn
        ld a,e
        or a
        jr nz,.pant
        ld a,c
        cp 106
        jr c,.pant
        cp 114
        ld b,4
        jr c,.row240
        ld b,5
        jr .row240
.pant:
        ld a,c
        and 16
        ld b,0
        jr z,.pant_frame
        inc b
.pant_frame:
        ld a,e
        or a
        jr nz,.row288
        inc b
        inc b
        jr .row240
.turn:
        ld a,e
        or a
        jr z,.row240
        ld a,b
        add a,6
        ld b,a
.row240:
        ld a,0xf0
        ld c,0x0e
        jr .set
.row288:
        ld a,0x20
        ld c,0x0f
.set:
        ld (0xc302),a
        ld a,c
        ld (0xc303),a
        ld a,b
        add a,a
        add a,a
        add a,a
        add a,a
        add a,a
        ld (0xc300),a
        scf
        ret

; HL -> source x, source y low byte (y=0x0Fxx in the actor atlas), width,
; height, destination x, y: a transparent copy to the hidden page.
label_blit:
        push hl
        ld hl,sprite_template
        call copy_command
        pop hl
        ld a,(hl)
        ld (0xc300),a
        inc hl
        ld a,(hl)
        ld (0xc302),a
        ld a,0x0f
        ld (0xc303),a
        inc hl
        ld a,(hl)
        ld (0xc308),a
        inc hl
        ld a,(hl)
        ld (0xc30a),a
        inc hl
        ld a,(hl)
        ld (0xc304),a
        inc hl
        ld a,(hl)
        ld (0xc306),a
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        jp command
label_player:  db 0,0x50,64,10,28,96
label_nick:    db 64,0x50,48,10,36,108
label_made_it: db 112,0x50,88,10,16,122
; Lost: above the runner, who stands where the clock stopped him.
label_player_lost: db 0,0x50,64,10,28,48
label_nick_lost:   db 64,0x50,48,10,36,60
label_blew_it:     db 0,0x66,88,10,16,74
label_goal:    db 200,0x50,32,10,172,122
label_cpu:     db 0,0x5c,72,10,152,96
label_1p:      db 96,0x66,16,10,24,SCORE_ROW
label_colon:   db 80,0x5c,8,10,56,0
label_dot:     db 88,0x5c,8,10,80,0

; HL -> x, y, width, height (bytes): fill that area of the hidden page
; with colour 0.
clear_area:
        push hl
        ld hl,clear_template
        call copy_command
        pop hl
        ld a,(hl)
        ld (0xc304),a
        inc hl
        ld a,(hl)
        ld (0xc306),a
        inc hl
        ld a,(hl)
        ld (0xc308),a
        ; Width 0 stands for 256.
        or a
        ld a,0
        jr nz,.width_ready
        inc a
.width_ready:
        ld (0xc309),a
        inc hl
        ld a,(hl)
        ld (0xc30a),a
        xor a
        ld (0xc30b),a
        ld a,(0xc704)
        ld (0xc307),a
        ld hl,0xc300
        jp command
clear_separator: db 120,0,8,184
clear_margin:    db 248,0,8,184
clear_hud:       db 0,184,0,28

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
        include "psg_calls.asm"
        include "step3_camera.asm"
; The arcade's mines blink a red 2x2 dot in their dark centre: lit about 10
; frames in every 32 (MAME: 8 in 24). Table: world row of the dot's top and
; its x (tools/build_ironman_course.py, the two mines of the course); the
; screen row of world row Y is camera + 183 - Y (C708, see lane).
draw_mine_dots:
        ld a,(0xfc9e)
        and 31
        cp 10
        ret nc
        ld ix,mine_dots
.next:
        ld e,(ix+0)
        ld d,(ix+1)
        ld a,d
        inc a
        ret z                   ; FFFFh ends
        ld hl,(0xc708)
        ld bc,183
        add hl,bc
        or a
        sbc hl,de               ; screen row of the dot's top
        jr c,.skip
        ld a,h
        or a
        jr nz,.skip
        ld a,l
        cp 183
        jr nc,.skip             ; both rows inside the lane (0..183)
        push af
        ld hl,mine_dot_template
        call copy_command
        pop af
        ld (0xc306),a
        ld a,(0xc704)
        ld (0xc307),a
        ld a,(0xc706)
        or a
        ld a,0
        jr z,.lane_x
        ld a,128
.lane_x:
        add a,(ix+2)
        ld (0xc304),a
        ld hl,0xc300
        call command
.skip:
        inc ix
        inc ix
        inc ix
        jr .next
mine_dots:
        dw 878
        db 40
        dw 1995
        db 103
        dw 0xffff
mine_dot_template:
        dw 0,0,0,0,2,2
        db 0,0x0c,0xff,0xff,0xdd,0xdd,0,0,0x20   ; LMMV, pen 13 (red)
bg_template:
        dw 0,512,0,0,120,184
        db 0,0x0c,0xff,0xff,0,0,0,0,0x40
clear_template:
        dw 0,0,0,0,256,212
        db 0,0x0c,0xff,0xff,0,0,0,0,0x20
sprite_template:
        dw 0,768,0,0,16,16
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
actor_template:
        dw 0,1280,0,0,24,32
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
result_template:
        dw 160,768,40,12,64,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
clock_template:
        dw 0,784,0,0,8,10
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
bonus_label_template:
        dw 96,792,30,24,32,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
bonus_sec_template:
        dw 136,792,78,24,24,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
power_label_template:
        dw 160,784,3,176,36,8
        db 0,0x1c,0xff,0xff,0,0,0,0,0x40
power_bg_template:
        dw 0,0,42,176,60,7
        db 0,0x0c,0xff,0xff,0x55,0x55,0,0,0x20
regs:   db 0x81,0,0x42,0
settings: db 0,0,0,0,0,0,0,0
palette: incbin "../build/step3/visual-palette.bin"
; Arcade palette entry 28 during the river (5-bit R, G, B).
water_cycle: db 0,17,22, 0,18,23, 0,19,24, 0,21,25
        assert $ <= 0x8000
        ds 0x8000-$,0xff
        incbin "../build/step3/visual-world.bin"
        incbin "../build/step3/visual-atlas.bin"
        ds 0x14000-$,0xff
        incbin "../build/step3/visual-water.bin"   ; river objects atlas
        incbin "../build/step3/visual-actors.bin"
        ds 0x20000-$,0xff
        incbin "../build/step3/visual-land.bin"
        incbin "../build/step3/visual-land-collision.bin"
        incbin "../build/step3/visual-land-surfaces.bin"
        ds 0x64000-$,0xff
        incbin "../build/step3/visual-finish.bin"  ; arcade runner poses
        ds 0x84000-$,0xff
