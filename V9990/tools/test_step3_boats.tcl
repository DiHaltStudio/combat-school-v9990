set throttle off
after time 10 {
    poke 0xc700 8
    poke 0xc701 8
    poke 0xc714 32
    poke 0xc712 0
    poke 0xc713 240
    poke 0xc716 0
    poke 0xc718 0
    poke 0xc71a 0
    poke 0xc71c 32
    poke 0xc71e 8
    poke 0xc71f 8
    poke 0xc710 0
}
after time 10.2 {
    set ::picked [peek 0xc71a]
    poke 0xc700 220
    poke 0xc701 10
    poke 0xc72a 64
    poke 0xc72b 0
    poke 0xc770 0
    poke 0xc710 12
}
after time 10.7 {
    set ::lost [peek 0xc718]
    set ::stun [peek 0xc712]
    set ::log_pos [peek 0xc72a]
    set ::progress [peek 0xc700]
    poke 0xc700 88
    poke 0xc701 8
    poke 0xc702 92
    poke 0xc703 8
    poke 0xc714 32
    poke 0xc715 32
    poke 0xc712 0
    poke 0xc713 0
    poke 0xc716 0
    poke 0xc710 0
    poke 0xc718 1
    poke 0xc719 3
    poke 0xc71a 1
    poke 0xc71b 0
}
after time 11.0 {
    set f [open $::env(STEP3_BOAT_RESULT) w]
    puts $f "$::picked $::lost $::stun [peek 0xc71a] [peek 0xc71b] [peek 0xc718] [peek 0xc712] $::log_pos $::progress"
    close $f
    exit
}
