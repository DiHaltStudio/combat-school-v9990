set throttle off
proc setup {position x} {
    poke 0xc700 [expr {$position&255}]
    poke 0xc701 [expr {$position>>8}]
    poke 0xc714 $x
    poke 0xc710 12
    poke 0xc712 0
    poke 0xc713 240
    poke 0xc71a 0
    poke 0xc716 0
}
after time 10 {setup 2232 4}
after time 10.3 {set ::rock [peek 0xc712];setup 2232 60}
after time 10.6 {set ::avoid [peek 0xc712];setup 2780 32; poke 0xc72a 64; poke 0xc72b 0}
after time 10.9 {
    set f [open $::env(STEP3_WATER_OBSTACLES_RESULT) w]
    puts $f "$::rock $::avoid [peek 0xc712] [peek 0xc71a]"
    close $f
    exit
}
