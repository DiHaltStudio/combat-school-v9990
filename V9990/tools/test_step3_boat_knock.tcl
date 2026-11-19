# A swimmer touching the other runner's boat throws him into the river.
set throttle off
after time 10 {
    poke 0xc700 [expr {2300&255}]; poke 0xc701 [expr {2300>>8}]
    poke 0xc702 [expr {2290&255}]; poke 0xc703 [expr {2290>>8}]
    poke 0xc714 40; poke 0xc715 44
    poke 0xc718 1; poke 0xc71a 1; poke 0xc71b 0
    poke 0xc71c 40; poke 0xc71e [expr {2300&255}]; poke 0xc71f [expr {2300>>8}]
    poke 0xc712 0; poke 0xc713 0; poke 0xc716 0; poke 0xc730 0
}
after time 10.3 {
    set f [open $::env(STEP3_BOAT_KNOCK_RESULT) w]
    puts $f "[peek 0xc71a] [peek 0xc712] [peek 0xc718]"
    close $f
    exit
}
