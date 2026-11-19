set throttle off
set ::out $::env(SHOOT_OUT)
file mkdir $::out
after time 12 {
    poke 0xc0df 8
    poke 0xc0de 0
    poke 0xc0d5 1
}
proc save_hud {name} {
    foreach {suffix dev size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
        set f [open $::out/$name-$suffix.bin w];fconfigure $f -translation binary
        puts -nonewline $f [debug read_block $dev 0 $size];close $f
    }
}
proc wait_hud {} {
    if {[peek 0xc418]==4} {
        poke 0xc434 1
        after time 0.5 {save_hud one; poke 0xc434 23}
        after time 1.0 {save_hud twentythree; poke 0xc434 44}
        after time 1.5 {save_hud fortyfour; poke 0xc434 45}
        after time 2.0 {save_hud fortyfive; poke 0xc434 67}
        after time 2.5 {save_hud sixtyseven; poke 0xc434 89}
        after time 3.0 {save_hud eightynine; exit}
    } else {
        if {[machine_info time]>30} {exit 1}
        after frame wait_hud
    }
}
after time 12.1 wait_hud
