set throttle off
set ::out $::env(SHOOT_PROGRESS_OUT)
file mkdir $::out
set ::seen_bonus 0
set ::seen_map 0
set ::seen_other 0
proc save_stage {name} {
    foreach {suffix dev size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64 pal "Sunrise GFX9000 palette" 256 memory memory 65536} {
        set f [open $::out/$name-$suffix.bin w]; fconfigure $f -translation binary
        puts -nonewline $f [debug read_block $dev 0 $size]; close $f
    }
}
after time 12 {
    poke 0xc0df 8
    poke 0xc0de 0
    poke 0xc0d5 1
}
proc wait_range_for_progress {} {
    if {[peek 0xc418]==4} {
        poke 0xc434 $::env(SHOOT_HITS)
        poke 0xc435 1
        set time [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc0dd]-2)&65535}]
        poke 0xc436 [expr {$time&255}]
        poke 0xc437 [expr {$time>>8}]
        after frame watch_shoot_progress
    } else {after frame wait_range_for_progress}
}
proc watch_shoot_progress {} {
    set stage [peek 0xc418]
    if {$stage==5 && !$::seen_bonus} {save_stage bonus;set ::seen_bonus 1}
    if {$stage==6 && !$::seen_map} {
        set ::map_page [expr {[debug read "Sunrise GFX9000 regs" 18]&1}]
        save_stage map; set ::seen_map 1
    }
    if {$stage==6 && $::seen_map && !$::seen_other && ([debug read "Sunrise GFX9000 regs" 18]&1)!=$::map_page} {
        save_stage map-other;set ::seen_other 1
    }
    if {$::seen_bonus && $::seen_map && $::seen_other} {exit}
    if {[machine_info time]>60} {exit 1}   ;# the bonus screen lasts as long as its music
    after frame watch_shoot_progress
}
after time 12.1 wait_range_for_progress
after time 62 {exit 1}
