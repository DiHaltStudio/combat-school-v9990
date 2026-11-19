set throttle off
proc prepare {} {
    poke 0xc8e4 0x00
    poke 0xc8e5 0x06
    poke 0xc950 110
    for {set i 0} {$i<16} {incr i} {poke [expr {0xc900+$i}] 0}
    poke 0xc900 1
    poke 0xc901 1
    poke 0xc910 80
    poke 0xc911 200
    poke 0xc920 40
    poke 0xc921 20
    poke 0xc809 0
    poke 0xc866 0
    poke 0xc865 0
}
after time 10 {prepare;poke 0xc801 100;poke 0xc802 50;poke 0xc803 1}
after time 10.2 {set ::miss [peek 0xc809];poke 0xc920 40;poke 0xc801 84;poke 0xc802 50;poke 0xc803 1}
after time 10.4 {
    set f [open $::env(STEP4_HITBOX_RESULT) w]
    puts $f "$::miss [peek 0xc809] [peek 0xc900] [peek 0xc9ee]"
    close $f
    exit
}
