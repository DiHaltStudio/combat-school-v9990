set throttle off
after time 10 {poke 0xc85a 1;poke 0xc866 254}
after time 10.2 {set ::x [peek 0xc848];set ::wave [peek 0xc85a]}
after time 10.7 {
    set ::distance [expr {[peek 0xc848]-$::x}]
    for {set i 0} {$i<8} {incr i} {poke [expr {0xc840+$i}] 0}
}
after time 11.2 {
    set f [open $::env(STEP4_CADENCE_RESULT) w]
    puts $f "$::distance $::wave [peek 0xc85a]"
    close $f
    exit
}
