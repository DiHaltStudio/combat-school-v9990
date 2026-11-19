set throttle off
proc setup {x} {
    poke 0xc8e4 0x00; poke 0xc8e5 0x06
    for {set i 0} {$i<16} {incr i} {poke [expr {0xc900+$i}] 0}
    poke 0xc900 1; poke 0xc910 $x; poke 0xc920 80; poke 0xc930 1
}
after time 10 {setup 100}
after time 10.2 {set ::normal [peek 0xc8f4]; setup 250}
after time 10.4 {
    set f [open $::env(STEP4_CLIPPING_RESULT) w]
    puts $f "$::normal [peek 0xc8f4]"
    close $f; exit
}
