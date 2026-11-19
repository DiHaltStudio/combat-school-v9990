set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc state {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc8da] [peek 0xc891] [peek 0xc8a2] [peek 0xc8d5] [peek 0xc856] [expr {[peek 0xc892]+256*[peek 0xc893]}] $::frames [expr {[peek 0xc840]+256*[peek 0xc841]}]";close $f
}
proc watch_bottle {} {
 incr ::frames
 if {[peek 0xc8a2]==1 && [peek 0xc893]==4} {state bottle;after time 0.08 {after frame watch_stationary};return}
 after frame watch_bottle
}
proc watch_stationary {} {
 if {[peek 0xc893]!=4} {after frame watch_stationary;return}
 state bottle-later
 set ::videosource GFX9000;screenshot "$::out/bottle.png";exit
}
proc setup {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame setup;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8
 poke 0xc840 73;poke 0xc841 4;poke 0xc801 96;poke 0xc856 8;poke 0xc823 0
 poke 0xc8da 0;poke 0xc8a2 0
 after time 0.2 {state before;poke 0xc840 72;after frame watch_bottle}
}
set ::frames 0
after time 10 {after frame setup}
after time 30 {exit 1}
