set throttle off
set ::out $::env(STEP4_TEST_OUT)
file mkdir $::out
after time 10 {
    set ::videosource GFX9000
    set ::original [peek 0xc800]
    keymatrixdown 8 128
}
after time 10.3 {
    set ::moved [peek 0xc800]
    keymatrixup 8 128
    poke 0xc940 0
    poke 0xc8e4 0x00
    poke 0xc8e5 0x06
    poke 0xc950 110
    poke 0xc941 0
    poke 0xc920 100
    poke 0xc900 1
    poke 0xc901 1
    poke 0xc902 0
    poke 0xc903 0
    poke 0xc910 80
    poke 0xc911 200
    poke 0xc921 20
    poke 0xc904 0
    poke 0xc905 0
    poke 0xc906 0
    poke 0xc907 0
    poke 0xc800 66
    poke 0xc803 0
    poke 0xc809 0
    keymatrixdown 8 1
}
after time 10.6 {
    keymatrixup 8 1
    set ::hits [peek 0xc809]
    set ::target [peek 0xc900]
    screenshot -raw "$::out/playing.png"
    set f [open "$::out/result.txt" w]
    puts $f "$::original $::moved $::hits $::target [peek 0xc806]"
    close $f
    exit
}
