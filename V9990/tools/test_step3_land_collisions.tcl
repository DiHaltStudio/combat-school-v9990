set throttle off
proc setup_runner {low high x} {
    poke 0xc700 $low
    poke 0xc701 $high
    poke 0xc714 $x
    poke 0xc710 12
    poke 0xc70f 0
    poke 0xc712 0
    poke 0xc740 0
    poke 0xc744 0
    poke 0xc713 240
}
after time 10 {setup_runner 96 0 56}
after time 10.25 {
    set ::early_fall [peek 0xc712]
    set ::early_kind [peek 0xc740]
    setup_runner 48 3 34
}
after time 10.5 {
    set ::late_fall [peek 0xc712]
    set ::late_kind [peek 0xc740]
    setup_runner 184 1 72
}
after time 10.75 {
    set ::avoid_fall [peek 0xc712]
    set ::avoid_pos [peek 0xc700]
    setup_runner 240 2 88
}
after time 11.0 {
    set f [open $::env(STEP3_LAND_COLLISION_RESULT) w]
    puts $f "$::early_fall $::early_kind $::late_fall $::late_kind $::avoid_fall $::avoid_pos [peek 0xc712]"
    close $f
    exit
}
