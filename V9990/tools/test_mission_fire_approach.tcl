set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc camera {x} {poke 0xc840 [expr {$x&255}];poke 0xc841 [expr {$x>>8}];poke 0xc801 96}
proc capture {name} {
 set f [open "$::out/$name.txt" w];puts $f "[peek 0xc900] [peek 0xc8a2] [peek 0xc856]";close $f
 set ::videosource GFX9000;screenshot -raw "$::out/$name.png"
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 0;poke 0xc930 1;poke 0xc911 5;poke 0xc8ad 8
 poke 0xc900 1;poke 0xc990 0;poke 0xc856 8;poke 0xc8dd 1;poke 0xca02 0
 camera 650
 poke 0xc8a0 138;poke 0xc8a1 2;poke 0xc8a2 1;poke 0xc8a3 0;poke 0xc8b2 190;poke 0xc8b3 2;poke 0xc8b4 0;poke 0xc8d5 2
 after time 0.4 {
  capture before
  camera 620
  after time 0.4 {capture partial;camera 580;after time 0.4 {capture full;exit}}
 }
}
after time 10 {after frame ready}
after time 25 {exit 1}
