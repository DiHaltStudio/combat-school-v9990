set throttle off
after time 10 {
    poke 0xc700 184
    poke 0xc701 1
    poke 0xc702 188
    poke 0xc703 1
    poke 0xc714 72
    poke 0xc715 72
    poke 0xc712 0
    poke 0xc713 0
    poke 0xc716 0
    poke 0xc710 0
    poke 0xc70f 0
    poke 0xc73f 8
}
after time 10.2 {
    set ::contact [peek 0xc712]
    poke 0xc700 88
    poke 0xc701 8
    poke 0xc702 100
    poke 0xc703 8
    poke 0xc714 32
    poke 0xc715 72
    poke 0xc712 0
    poke 0xc713 0
    poke 0xc716 0
    poke 0xc710 12
    set ::videosource GFX9000
    keymatrixdown 4 4
}
after time 10.25 {
    # Repeat in case the first write met a CPU update in progress.
    poke 0xc702 100
    poke 0xc703 8
}
after time 10.5 {
    keymatrixup 4 4
    set f [open "$::env(STEP3_RIVER_OUT)/result.txt" w]
    puts $f "$::contact [peek 0xc70f] [peek 0xc701] [peek 0xc703]"
    close $f
    screenshot -raw "$::env(STEP3_RIVER_OUT)/river.png"
    exit
}
