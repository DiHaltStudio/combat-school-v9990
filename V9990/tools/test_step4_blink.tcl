set throttle off
set ::out $::env(STEP4_BLINK_OUT)
file mkdir $::out
proc setup {} {
    set ::videosource GFX9000
    poke 0xc8e4 0x00; poke 0xc8e5 0x06
    for {set i 0} {$i<16} {incr i} {poke [expr {0xc900+$i}] 0}
    poke 0xc900 1; poke 0xc910 100; poke 0xc920 110; poke 0xc930 1
}
after time 10 setup
after time 10.4 {set ::a [peek 0xc8f5];screenshot -raw "$::out/a.png"}
after time 10.6 {
    set f [open "$::out/result.txt" w]
    puts $f "$::a [peek 0xc8f5]"
    close $f; screenshot -raw "$::out/b.png";exit
}
