; Dedicated blue knife thrower at the industrial side of the doorway.
; c8c0..cb: actor; c8d0: one-shot spawn latch.
; Arcade (tools/mame_mission_positions.lua, record $0d80): it appears when
; the camera reaches 1358 (ROM world = arcade + 99), 11 px outside the left
; edge, and stays at 1347 (centre) without walking, just left of the wall
; edge, so its knives start behind the doorway frame.
mission_fourth_tick:
        ld a,(0xc856)
        or a
        ret z
        ld a,(0xc8d0)
        or a
        jr nz,.existing
        ld hl,(0xc840)
        ld de,1359
        or a
        sbc hl,de
        ret nc
        ld a,1
        ld (0xc8d0),a
        ld (0xc8c1),a
        ld hl,1347-32           ; sprite origin: centre 1347
        ld (0xc8c2),hl
        xor a
        ld (0xc8c5),a
        ld (0xc8c8),a
        ld (0xc8ca),a
        ld a,75
        ld (0xc89c),a           ; brief approach before the first throw
.existing:
        ld a,(0xc8c1)
        or a
        ret z
        cp 5
        ret nc
        call mission_swap_fourth
        ld a,3                  ; blue actor with projectile ability
        ld (0xc86f),a
        ld a,1                  ; doorway attacker throws knives
        ld (0xc8ac),a
        ld (0xc9a4),a           ; and never leaves its place (arcade)
        call mission_enemy_tick
        call mission_swap_fourth
        xor a
        ld (0xc86f),a
        ld (0xc8ac),a
        ld (0xc9a4),a
        ret

mission_fourth_draw:
        ld a,(0xc8c1)
        or a
        ret z
        cp 5
        ret nc
        call mission_swap_fourth
        ld a,3
        ld (0xc86f),a
        ld a,(0xc89c)
        cp 151
        jr c,.draw_normal
        cp 171
        jr nc,.draw_normal
        ld a,(0xc851)
        cp 1
        jr nz,.draw_normal
        call mission_draw_knife_throw
        jr .draw_done
.draw_normal:
        call mission_draw_enemy
.draw_done:
        call mission_swap_fourth
        xor a
        ld (0xc86f),a
        ret

; Three arcade upper-body poses, with the raised hand kept inside the copy.
mission_draw_knife_throw:
        ld hl,(0xc852)
        ld de,(0xc840)
        or a
        sbc hl,de
        ret c
        ld a,h
        or a
        ret nz
        ld a,l
        cp 193
        ret nc
        add a,15
        ld (0xc85b),a
        ld hl,actor_template
        call copy_command
        ld a,(0xc85b)
        ld (0xc304),a
        ld hl,(0xc852)
        ld de,32
        add hl,de
        call mission_floor_at_world
        add a,104
        ld (0xc306),a
        ld a,(0xc802)
        ld (0xc307),a
        ld a,(0xc89c)
        cp 165
        ld b,0
        ld c,96                 ; atlas y=2912
        jr nc,.pose_ready
        cp 158
        ld b,128
        jr nc,.pose_ready
        ld b,0
        ld c,160                ; atlas y=2976
.pose_ready:
        ld a,(0xc85a)
        or a
        ld a,b
        jr z,.pose_facing_ready
        add a,64
.pose_facing_ready:
        add a,15
        ld (0xc300),a
        ld a,c
        ld (0xc302),a
        ld a,11
        ld (0xc303),a
        ld a,34
        ld (0xc308),a
        ld a,64
        ld (0xc30a),a
        ld hl,0xc300
        jp command

mission_swap_fourth:
        ; Word exchanges without a loop: c850..c855, c85a..c85b and c858
        ; against the actor record at 0xc8c0.
        ld hl,(0xc850)
        ld de,(0xc8c0)
        ld (0xc8c0),hl
        ld (0xc850),de
        ld hl,(0xc852)
        ld de,(0xc8c2)
        ld (0xc8c2),hl
        ld (0xc852),de
        ld hl,(0xc854)
        ld de,(0xc8c4)
        ld (0xc8c4),hl
        ld (0xc854),de
        ld hl,(0xc85a)
        ld de,(0xc8ca)
        ld (0xc8ca),hl
        ld (0xc85a),de
        ld a,(0xc858)
        ld b,a
        ld a,(0xc8c8)
        ld (0xc858),a
        ld a,b
        ld (0xc8c8),a
        ret

; Doorway walls in front of the actors. In the arcade the actors pass behind
; the wall of each doorway: the dark wall edge (world 1354..1361) and the pink
; wall face beside the opening (1371..1378) between the pink room and the
; industrial area, and the green wall left of the opening into the brick room
; (477..500). Two methods, chosen by cost (make test-mission-walk-timing):
; - brick room (24 px wide): actor copies (`command`, rows from 32) are cut
;   at the wall, so the restored background stays visible there;
; - pink room (the wall and the intervening dark gap, where the player
;   crosses): these columns are copied again over the actors at the end of
;   the frame (mission_door_front), which costs less than splitting copies.
; Clip spans sorted by X: [start, end).
door_clip_spans:
        dw 477,501
        dw 0

; Once per frame, before the actors: the spans on screen are copied to CF62
; (start, end words; ended by a zero word), CF6E/CF70 = first start and last
; end, CF72/CF73 = their first and last screen column, and CF17 = 1 when
; there is at least one.
mission_door_setup:
        xor a
        ld (0xcf17),a
        ld hl,door_clip_spans
        ld ix,0xcf62
.span:
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,d
        or e
        jr z,.end
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        push hl
        ld hl,(0xc840)
        or a
        sbc hl,bc
        jr nc,.hidden           ; camera at or after the end
        ld hl,(0xc840)
        inc h
        or a
        sbc hl,de
        jr c,.hidden            ; start after the screen
        jr z,.hidden
        ld a,(0xcf17)
        or a
        jr nz,.listed
        ld (0xcf6e),de
        inc a
        ld (0xcf17),a
.listed:
        ld (ix+0),e
        ld (ix+1),d
        ld (ix+2),c
        ld (ix+3),b
        ld (0xcf70),bc
        inc ix
        inc ix
        inc ix
        inc ix
.hidden:
        pop hl
        jr .span
.end:
        ld (ix+0),a
        ld (ix+1),a
        ld a,(0xcf17)
        or a
        ret z
        ; Screen columns of the union for the quick test in `command`:
        ; CF72 = first (0 if it starts left of the screen), CF73 = last.
        ld hl,(0xcf6e)
        ld de,(0xc840)
        or a
        sbc hl,de
        jr nc,.first
        ld hl,0
.first:
        ld a,l
        ld (0xcf72),a
        ld hl,(0xcf70)
        dec hl
        or a
        sbc hl,de
        ld a,h
        or a
        ld a,l
        jr z,.last
        ld a,255
.last:
        ld (0xcf73),a
        ret

; Called by `command` with the copy in C300 and its world X in CF18.
; Emits the parts left of each visible span it crosses and leaves the rest
; in C300 (Z: nothing left to draw).
door_clip:
        ld hl,0xcf62
.span:
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl                  ; DE = start
        ld a,d
        or e
        jr z,.rest
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl                  ; BC = end
        push hl
        ld hl,(0xcf18)
        or a
        sbc hl,bc
        jr nc,.next             ; copy starts after this span
        ld hl,(0xcf18)
        push de
        ld de,(0xc308)
        add hl,de               ; HL = copy end
        pop de
        push hl
        or a
        sbc hl,de
        pop hl
        jr c,.finish            ; copy ends before this span (and the rest)
        jr z,.finish
        push hl
        push bc
        ex de,hl
        ld de,(0xcf18)
        or a
        sbc hl,de               ; part left of the span
        jr c,.no_left
        call nz,door_emit_part
.no_left:
        pop bc
        pop hl
        or a
        sbc hl,bc               ; part right of the span
        jr c,.nothing
        jr z,.nothing
        ld (0xc308),hl
        ld h,b
        ld l,c
        ld de,(0xcf18)
        ld (0xcf18),hl
        or a
        sbc hl,de               ; columns skipped
        ld a,(0xc300)
        add a,l
        ld (0xc300),a           ; source X (atlas X + width <= 256)
.next:
        pop hl
        jr .span
.nothing:
        pop hl
        xor a
        ret
.finish:
        pop hl
.rest:
        or 1
        ret

; Emits C300 with width HL at world X CF18, leaving C300..C30B as they were.
door_emit_part:
        ld de,(0xc308)
        push de
        ld a,(0xc306)
        push af
        ld (0xc308),hl
        ld a,(0xcf19)
        ld hl,0xc306
        add a,(hl)
        ld (hl),a
        ld a,(0xcf18)
        ld (0xc304),a
        call mission_ring_emit
        pop af
        ld (0xc306),a
        pop de
        ld (0xc308),de
        ret

; Pink room doorway: after every actor and effect is drawn, copy the wall
; columns and dark gap again from the stored room strip (no new graphics), only over the
; rows of this frame's drawn rectangles (dirty list of the hidden page, see
; mission_ring.asm) that touch them, and clipped to the screen.
; Scratch: cf10 group start, cf12 group end, cf16 X, cf1e width.
DOOR_FRONT_START equ 1354
DOOR_FRONT_END equ 1379
mission_door_front:
        call door_front_rows
        ret c
        ld hl,DOOR_FRONT_START
        ld c,DOOR_FRONT_END-DOOR_FRONT_START
        jp door_front_range

; Carry: walls not visible or not touched. Otherwise cf14/cf15 = rows.
door_front_rows:
        ld hl,(0xc840)
        ld de,DOOR_FRONT_END
        or a
        sbc hl,de
        ccf
        ret c                   ; camera at or after the walls' end
        ld hl,(0xc840)
        inc h
        ld de,DOOR_FRONT_START
        or a
        sbc hl,de
        ret c                   ; walls still to the right of the screen
        scf
        ret z
        ld a,(0xc802)
        ld e,a
        ld d,0
        ld hl,0xca20
        add hl,de
        ld a,(hl)
        or a
        scf
        ret z
        ld b,a                  ; records on this page
        ld a,e
        add a,0xcb
        ld h,a
        ld l,0
        ld de,0x00ff            ; D = bottom, E = top
.rect:
        push bc
        push hl
        ld c,(hl)
        inc hl
        ld b,(hl)               ; BC = world X
        inc hl
        push hl
        ld hl,DOOR_FRONT_END-1
        or a
        sbc hl,bc
        pop hl
        jr c,.next              ; starts after the walls
        ld a,(hl)               ; y
        inc hl
        push af
        ld a,(hl)
        inc hl
        push hl
        ld h,(hl)
        ld l,a
        add hl,bc               ; end X
        push de
        ld de,DOOR_FRONT_START+1
        or a
        sbc hl,de
        pop de
        pop hl
        jr c,.skip              ; ends before the walls
        inc hl                  ; height (record +5)
        pop af
        cp e
        jr nc,.top
        ld e,a
.top:
        add a,(hl)
        jr c,.bottom_max
        cp 212
        jr c,.bottom
.bottom_max:
        ld a,212
.bottom:
        cp d
        jr c,.next
        ld d,a
        jr .next
.skip:
        pop af
.next:
        pop hl
        ld bc,7
        add hl,bc
        pop bc
        djnz .rect
        ld a,d
        sub e
        jr z,.untouched
        jr c,.untouched         ; nothing drawn over the walls
        ld (0xcf15),a
        ld a,e
        ld (0xcf14),a
        or a
        ret
.untouched:
        scf
        ret

; HL = world X, C = width, rows in cf14/cf15.
door_front_range:
        ld (0xcf16),hl
        ld a,c
        ld (0xcf1e),a
        ld de,(0xc840)
        or a
        sbc hl,de               ; X - camera
        jr c,door_front_clip
        ld a,h
        or a
        jr nz,door_front_clip
        ld a,l
        add a,c
        jr nc,.inside
        jr nz,door_front_clip
.inside:
        ; Whole wall visible and within one ring row: one LMMM written
        ; directly. Ring page X = X mod 256, Y + X/256; stored strip
        ; X/256 at VRAM y=256*(X/256+5), or +3 after the HUD storage.
        ld hl,(0xcf16)
        ld a,l
        add a,c
        jr nc,.one_row
        jr nz,door_front_clip
.one_row:
        ld a,h
        add a,5
        cp 9
        jr c,.strip
        add a,3
.strip:
        ld e,a
.idle:
        in a,(0x65)
        rrca
        jr c,.idle
        ld a,32
        out (0x64),a
        ld c,0x63
        out (c),l               ; SX
        xor a
        out (c),a
        ld a,(0xcf14)
        out (c),a               ; SY
        out (c),e
        out (c),l               ; DX
        xor a
        out (c),a
        ld a,(0xcf14)
        add a,h
        out (c),a               ; DY = page*256 + top + X/256
        ld a,(0xc802)
        out (c),a
        ld a,(0xcf1e)
        out (c),a               ; NX
        xor a
        out (c),a
        ld a,(0xcf15)
        out (c),a               ; NY
        xor a
        out (c),a
        out (c),a               ; ARG
        ld b,0x0c
        out (c),b               ; LOP: copy
        dec a
        out (c),a               ; write mask
        out (c),a
        inc a
        out (c),a               ; colours
        out (c),a
        out (c),a
        out (c),a
        ld b,0x40
        out (c),b               ; LMMM
        ret

; Visible part [max(X,camera), min(X+W,camera+256)) through the general
; ring restore, which also splits copies at the ring seam.
door_front_clip:
        ld hl,(0xcf16)
        ld a,(0xcf1e)
        ld e,a
        ld d,0
        add hl,de
        ex de,hl                ; DE = X + W
        ld hl,(0xc840)
        inc h                   ; camera + 256
        or a
        sbc hl,de
        jr nc,.end_ready
        add hl,de
        ex de,hl                ; DE = camera + 256
.end_ready:
        ld hl,(0xcf16)
        ld bc,(0xc840)
        or a
        sbc hl,bc
        jr nc,.start_x
        ld hl,(0xc840)
        jr .start_ready
.start_x:
        ld hl,(0xcf16)
.start_ready:
        ex de,hl                ; DE = start, HL = end
        or a
        sbc hl,de
        ret c
        ret z
        ld b,h
        ld c,l                  ; BC = width
        ex de,hl                ; HL = start
        jp mission_ring_restore
