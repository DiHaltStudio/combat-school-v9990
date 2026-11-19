set throttle off
set ::out $::env(STEP4_EFFECTS_OUT)
file mkdir $::out
proc setup {} {
 set ::videosource GFX9000
 poke 0xc8e4 0x00;poke 0xc8e5 0x06
 for {set i 0} {$i<16} {incr i} {poke [expr {0xc900+$i}] 0}
 poke 0xc900 1;poke 0xc910 80;poke 0xc920 40;poke 0xc930 1;poke 0xc950 110
 poke 0xc801 84;poke 0xc802 50;poke 0xc803 1
}
after time 10 setup
after time 10.08 {
 set ::remaining [peek 0xc8f6]
 screenshot -raw "$::out/blast.png"
}
after time 10.8 {
 set f [open "$::out/result.txt" w]
 puts $f "$::remaining [peek 0xc8f6] [peek 0xc809] [peek 0xc9ee]"
 close $f;exit
}
