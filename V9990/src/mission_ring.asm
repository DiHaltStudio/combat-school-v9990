; B1 linear-address ring: physical X = world X modulo 256,
; physical Y = logical Y + floor(world X / 256). Scanout crossing X=255
; continues on the next row; R17 compensates the camera coarse X.
; RAM: CB00/CC00 dirty lists (32 records of 7 bytes); CA20..27 metadata;
; CF00 enable, CF01 recording; CF17 doorway walls on screen (mission_doorway.asm);
; CF10..1F scratch; CF40..54 split-command buffer.
; Each record: world X (word), Y, width (word), height (word).
mission_ring_init:
        xor a
        ld (0xca26),a
        ld (0xca27),a
        ld (0xca20),a
        ld (0xca21),a
        dec a
        ld (0xcf03),a
        xor a
        inc a
        ld (0xcf00),a
        ret

mission_ring_background:
        xor a
        ld (0xc9b8),a
        inc a
        ld (0xc9b9),a
        dec a
        ld (0xcf01),a
        ld a,(0xc802)
        or a
        ld hl,0xcb00
        ld ix,0xca20
        jr z,.selected
        inc h
        inc ix
.selected:
        ld a,(ix+6)
        or a
        jr z,.full
        ; Restore precisely the regions overwritten on this hidden page.
        ld a,(ix+0)
.restore:
        or a
        jr z,.strips
        push af
        push hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        ld (0xcf14),a
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld a,(hl)
        ld (0xcf15),a
        ex de,hl
        call mission_ring_restore
        pop hl
        ld de,7
        add hl,de
        pop af
        dec a
        jr .restore
.strips:
        ; Old camera words at CA22 and CA24, indexed by drawing page.
        ld a,(0xc802)
        add a,a
        ld e,a
        ld d,0
        ld hl,0xca22
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,(0xc840)
        or a
        sbc hl,de
        ld a,h
        or a
        jr z,.positive
        inc a
        jr nz,.full
        ld a,l
        neg
        cp 9
        jr nc,.full
        ld c,a
        ld b,0
        ld hl,(0xc840)
        jr .new_strip
.positive:
        ld a,l
        or a
        jr nz,.moving
        ld (0xc9b9),a
        jr .finished
.moving:
        cp 9
        jr nc,.full
        ld c,a
        ld b,0
        ex de,hl
        inc h                   ; old camera + 256: new right strip
        jr .new_strip
.full:
        ld hl,(0xc840)
        ld bc,256
.new_strip:
        ld a,32
        ld (0xcf14),a
        ld a,180
        ld (0xcf15),a
        call mission_ring_restore
.finished:
        ld a,(0xc802)
        add a,a
        ld e,a
        ld d,0
        ld hl,0xca22
        add hl,de
        ld de,(0xc840)
        ld (hl),e
        inc hl
        ld (hl),d
        ld (ix+0),0
        ld (ix+6),1
        ld a,(0xc9b9)
        or a
        jr z,.hud_retained
        ; HUD is screen-fixed: clear top band and redraw at the new ring X.
        ld hl,mission_ring_clear
        call copy_command
        ld a,(0xc802)
        ld (0xc307),a
        ld hl,0xc300
        call raw_command
        ld a,255
        ld (0xc8a6),a
        ld (0xc8a7),a
        ld (0xc8d2),a
        ld (0xc8d3),a
.hud_retained:
        ld a,1
        ld (0xcf01),a
        ret

; HL=world X, BC=width, CF14=y, CF15=height. Source strip and
; ring destination share the same boundary, so split both there.
mission_ring_restore:
        call mission_final_invalidate
        push hl
        push bc
        ld hl,field_template
        call copy_command
        pop bc
        pop hl
        ld a,l
        ld (0xc300),a
        ld (0xc304),a
        ld a,h
        add a,5
        cp 9
        jr c,.source
        add a,3
.source:
        ld (0xc303),a
        ld a,(0xcf14)
        ld (0xc302),a
        add a,h
        ld (0xc306),a
        ld a,(0xcf15)
        ld (0xc30a),a
        ld a,(0xc802)
        ld (0xc307),a
        ld (0xc308),bc
        ; Mark background split: source must advance to the next strip.
        ld a,1
        ld (0xcf02),a
        call mission_ring_emit
        xor a
        ld (0xcf02),a
        ret

command:
        ld a,(0xcf00)
        or a
        jp z,raw_command
        ld a,(0xc304)
        ld e,a
        ld d,0
        ld hl,(0xc840)
        add hl,de
        ld (0xcf18),hl
        call mission_ring_record
        ld a,(0xcf17)
        or a
        jr z,.emit
        ld a,(0xc306)
        cp 32
        jr c,.emit              ; HUD and score rows
        ; Quick test in screen columns: CF72..CF73 hold the doorway walls.
        ld a,(0xcf73)
        ld b,a
        ld a,(0xc304)
        cp b
        jr z,.door_test
        jr nc,.emit             ; starts after the walls
.door_test:
        ld b,a
        ld a,(0xc308)
        add a,b
        jr c,.door_clip         ; reaches the right edge
        ld b,a
        ld a,(0xcf72)
        cp b
        jr nc,.emit             ; ends before the walls
.door_clip:
        call door_clip
        ret z
.emit:
        ld a,(0xcf19)
        ld hl,0xc306
        add a,(hl)
        ld (hl),a
        ld a,(0xcf18)
        ld (0xc304),a
        jp mission_ring_emit

mission_ring_record:
        ld a,(0xcf01)
        or a
        ret z
        ld a,(0xc306)
        cp 32
        ret c
        ld a,(0xc802)
        ld e,a
        ld d,0
        ld hl,0xca20
        add hl,de
        ld a,(hl)
        cp 32
        jr c,.record
        ; Queue overflow must trigger a full restore next time, never ghosts.
        ld de,6
        add hl,de
        ld (hl),0
        ret
.record:
        ; Two actors drawn almost at the same place (same row and size, at
        ; most 4 pixels apart) share one record: one restore instead of two.
        or a
        jr z,.append
        push hl
        ld e,a
        dec a
        ld d,a
        add a,a
        add a,a
        add a,a
        sub d
        add a,2
        ld l,a
        ld a,(0xc802)
        add a,0xcb
        ld h,a                  ; HL = last record + 2 (y)
        ld a,(0xc306)
        cp (hl)
        jr nz,.no_merge
        inc hl
        ld a,(0xc308)
        cp (hl)
        jr nz,.no_merge
        inc hl
        ld a,(0xc309)
        cp (hl)
        jr nz,.no_merge
        inc hl
        ld a,(0xc30a)
        cp (hl)
        jr nz,.no_merge
        inc hl
        ld a,(0xc30b)
        cp (hl)
        jr nz,.no_merge
        dec hl
        dec hl
        dec hl
        dec hl
        dec hl                  ; +1
        push hl
        ld b,(hl)
        dec hl
        ld c,(hl)               ; BC = last X
        ld hl,(0xcf18)
        or a
        sbc hl,bc               ; HL = new X - last X
        jr c,.new_left
        ld a,h
        or a
        jr nz,.no_merge_pop
        ld a,l
        cp 5
        jr nc,.no_merge_pop
        pop hl                  ; +1
        jr .widen
.new_left:
        ld a,h
        inc a
        jr nz,.no_merge_pop
        ld a,l
        cp 0xfc
        jr c,.no_merge_pop
        neg
        pop hl                  ; +1
        ld de,(0xcf18)
        ld (hl),d
        dec hl
        ld (hl),e               ; X = new X
        inc hl
.widen:
        inc hl
        inc hl                  ; +3: width += distance
        add a,(hl)
        ld (hl),a
        inc hl
        ld a,(hl)
        adc a,0
        ld (hl),a
        pop hl
        ret
.no_merge_pop:
        pop hl
.no_merge:
        pop hl
        ld a,e
.append:
        inc (hl)
        ld e,a
        add a,a
        add a,a
        add a,a
        sub e
        ld l,a
        ld a,(0xc802)
        add a,0xcb
        ld h,a
        ld de,(0xcf18)
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld a,(0xc306)
        ld (hl),a
        inc hl
        ld de,0xc308
        ex de,hl
        ld bc,4
        ldir
        ret

mission_ring_emit:
        ld a,(0xc304)
        ld e,a
        ld d,0
        ld hl,256
        or a
        sbc hl,de
        ld de,(0xc308)
        or a
        sbc hl,de
        jr c,.split
        ld hl,0xc300
        jp raw_command
.split:
        add hl,de               ; HL=first width
        ld (0xcf1a),hl
        ld hl,0xc300
        ld de,0xcf40
        ld bc,21
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi
        ldi

        ld hl,(0xc308)
        ld de,(0xcf1a)
        or a
        sbc hl,de
        ld (0xcf48),hl          ; remaining width
        ld hl,(0xc300)
        add hl,de
        ld (0xcf40),hl
        ld a,(0xcf02)
        or a
        jr z,.source_ready
        xor a
        ld (0xcf40),a
        ld (0xcf41),a
        ld a,(0xcf43)
        inc a
        cp 9
        jr nz,.strip_ready
        ld a,12
.strip_ready:
        ld (0xcf43),a
.source_ready:
        ; The second span is fetched one scanline later in bitmap mode.
        ld hl,0xcf46
        inc (hl)
        xor a
        ld (0xcf44),a
        ld (0xcf45),a
        ld hl,(0xcf1a)
        ld (0xc308),hl
        ld hl,0xc300
        call raw_command
        ld hl,0xcf40
        jp raw_command

mission_ring_clear:
        dw 0,0,0,0,256,16
        db 0,0x0c,0xff,0xff,0,0,0,0,0x20
