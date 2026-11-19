set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc shot {cam} {
 poke 0xc840 [expr {$cam & 255}];poke 0xc841 [expr {$cam >> 8}]
 after time 0.3 [list capture $cam]
}
proc capture {cam} {
 set ::videosource GFX9000
 screenshot -raw "$::out/$cam.png"
 set f [open "$::out/$cam.txt" w];puts $f "[peek 0xc8e0] [peek 0xc856]";close $f
 if {$cam==710} {shot 707} elseif {$cam==707} {shot 700} elseif {$cam==700} {shot 690} elseif {$cam==690} {shot 680} else {exit}
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 0;poke 0xc8e9 0;poke 0xc930 1;poke 0xc911 5;poke 0xc8ad 8
 poke 0xc900 0;poke 0xc990 0;poke 0xc8dc 255;poke 0xc856 8;poke 0xc857 255;poke 0xc801 96
 shot 710
}
after time 10 {after frame ready}
after time 30 {exit 1}
