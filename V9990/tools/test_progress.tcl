set throttle off
set ::saved_bonus 0
set ::saved_map 0
set ::saved_other 0
set ::out $::env(PROGRESS_OUT)
file mkdir $::out
proc save_progress {name} {
    foreach {suffix dev count} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64 pal "Sunrise GFX9000 palette" 256 memory memory 65536} {
        set f [open $::out/$name-$suffix.bin w]
        fconfigure $f -translation binary
        puts -nonewline $f [debug read_block $dev 0 $count]
        close $f
    }
}
proc watch_progress {} {
    set phase [peek 0xc418]
    if {$phase == 2 && !$::saved_bonus} {save_progress bonus; set ::saved_bonus 1}
    if {$phase == 3 && !$::saved_map} {
        set ::map_page [expr {[debug read "Sunrise GFX9000 regs" 18]&1}]
        save_progress map
        set ::saved_map 1
    }
    if {$phase == 3 && $::saved_map && !$::saved_other && ([debug read "Sunrise GFX9000 regs" 18]&1) != $::map_page} {
        save_progress map-other
        set ::saved_other 1
    }
    if {$::saved_bonus && $::saved_map && $::saved_other} {exit}
    if {[machine_info time] > 28} {exit 1}
    after frame watch_progress
}
after time 12 {
    poke 0xc0df $::env(REMAINING)
    poke 0xc0de 0
    poke 0xc0d5 1
    poke 0xc095 $::env(CPU_FIRST)
}
after time 12.05 watch_progress
