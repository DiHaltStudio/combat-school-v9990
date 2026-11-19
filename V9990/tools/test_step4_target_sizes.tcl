set throttle off
proc set_target {y} {
    poke 0xc8e4 0x00
    poke 0xc8e5 0x06
    poke 0xc950 110
    for {set i 0} {$i<16} {incr i} {poke [expr {0xc900+$i}] 0}
    poke 0xc900 1
    poke 0xc930 1
    poke 0xc940 1
    poke 0xc910 100
    poke 0xc920 $y
    poke 0xc866 0
}
after time 10 {set_target 30}
after time 10.2 {set ::a [peek 0xc85d];set_target 70}
after time 10.4 {set ::b [peek 0xc85d];set_target 110}
after time 10.6 {set f [open $::env(STEP4_SIZE_RESULT) w];puts $f "$::a $::b [peek 0xc85d]";close $f;exit}
