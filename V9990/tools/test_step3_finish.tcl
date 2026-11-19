set throttle off
after time 10 {
    set ::log_before [peek 0xc72a]
    poke 0xc72e 0
    poke 0xc72f 0
    poke 0xc730 0
    poke 0xc731 8
    poke 0xc714 16
    poke 0xc715 88
    if {$::env(STEP3_WINNER) eq "player"} {
        poke 0xc701 13
        poke 0xc703 1
    } else {
        poke 0xc701 1
        poke 0xc703 13
    }
}
after time 10.2 {
    set ::winner [peek 0xc72e]
    set ::player_done [peek 0xc72f]
    set ::cpu_done [peek 0xc730]
    set ::log_after [peek 0xc72a]
    set ::seconds [peek 0xc731]
    poke 0xc701 13
    poke 0xc703 13
}
after time 10.4 {
    set f [open $::env(STEP3_FINISH_RESULT) w]
    puts $f "$::winner $::player_done $::cpu_done [peek 0xc72e] [peek 0xc72f] [peek 0xc730] $::log_before $::log_after $::seconds [peek 0xc731] [peek 0xc736]"
    close $f
    exit
}
