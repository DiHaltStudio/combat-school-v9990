set throttle off
after time 10 {
    poke 0xc731 10
    poke 0xc72f 0
    poke 0xc735 0
    set ::start [peek 0xc731]
}
after time 12 {
    set ::after_two [peek 0xc731]
    poke 0xc731 1
}
after time 14 {
    set f [open $::env(STEP3_CLOCK_RESULT) w]
    puts $f "$::start $::after_two [peek 0xc731] [peek 0xc735] [peek 0xc72e] [peek 0xc72f] [peek 0xc730]"
    close $f
    exit
}
