set throttle off
set ::out $::env(SHOOT_POSES_OUT)
file mkdir $::out
after time 12 {poke 0xc0df 8; poke 0xc0de 0; poke 0xc0d5 1}
proc save_pose {name} {
    foreach {suffix device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64 memory memory 65536} {
        set f [open $::out/$name-$suffix.bin w]; fconfigure $f -translation binary
        puts -nonewline $f [debug read_block $device 0 $size]; close $f
    }
}
proc wait_poses {} {
    if {[peek 0xc418]==4} {
        poke 0xc430 16
        after time 0.4 {save_pose left; poke 0xc430 104}
        after time 0.8 {save_pose center; poke 0xc430 200}
        after time 1.2 {save_pose right; exit}
    } else {
        if {[machine_info time]>30} {exit 1}
        after frame wait_poses
    }
}
after time 12.1 wait_poses
