set throttle off
set ::out $::env(STEP3_MINE_OUT)
file mkdir $::out
after time 10 {
    set ::videosource GFX9000
    poke 0xc700 48
    poke 0xc701 3
    poke 0xc714 34
    poke 0xc710 12
    poke 0xc70f 0
    poke 0xc712 0
    poke 0xc740 0
}
after time 10.15 {
    set ::mine [peek 0xc740]
    set ::fall [peek 0xc712]
    screenshot -raw "$::out/mine.png"
    poke 0xc700 96
    poke 0xc701 0
    poke 0xc714 56
    poke 0xc744 0
    poke 0xc701 0
    poke 0xc710 12
    poke 0xc712 0
}
after time 10.30 {
    set f [open "$::out/result.txt" w]
    puts $f "$::mine $::fall [peek 0xc740] [peek 0xc712]"
    close $f
    exit
}
