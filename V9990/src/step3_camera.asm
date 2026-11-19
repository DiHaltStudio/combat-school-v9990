; Project a runner into an independently scrolling vertical camera.
; HL = camera owner's world progress (0..65535), DE = runner progress.
; Output: A = screen Y and carry clear when 0 <= Y < 184; carry set when
; outside. The camera owner remains at Y=120. Other registers are clobbered.
; World positions differ by less than 32768 pixels during this stage.
step3_project_y:
        or a
        sbc hl,de
        ld de,120
        add hl,de
        ld a,h
        or a
        jr nz,.hidden
        ld a,l
        cp 184
        jr nc,.hidden
        or a
        ret
.hidden:
        scf
        ret
