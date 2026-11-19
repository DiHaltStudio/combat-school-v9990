set throttle off
after time 10 {
    poke 0xc700 80
    poke 0xc701 3
    poke 0xc714 40
    poke 0xc744 0
    poke 0xc710 12
    poke 0xc712 0
    poke 0xc70f 0
}
after time 10.2 {
    set ::crashed [peek 0xc712]
    poke 0xc700 80
    poke 0xc701 3
    poke 0xc714 40
    poke 0xc744 0
    poke 0xc710 12
    poke 0xc712 0
    poke 0xc70f 0
    keymatrixdown 4 4
}
after time 10.35 {
    set jump [peek 0xc70f]
    set collision [peek 0xc712]
    set pos [peek 0xc700]
    keymatrixup 4 4
    set f [open $::env(STEP3_OBSTACLE_RESULT) w]
    puts $f "$::crashed $jump $collision $pos"
    close $f
    exit
}
