set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::phase 0
proc start {phase} {
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 [expr {$phase==0?0:1}]
 poke 0xc8ea 149;poke 0xc8eb 2;poke 0xc8ed 0;poke 0xc8dc 255
 poke 0xc930 1;poke 0xc911 5;poke 0xc8ad 8;poke 0xc900 [expr {$phase==0?0:1}];poke 0xc990 0
 poke 0xc8a2 0;poke 0xca02 0;poke 0xc856 8;poke 0xc823 0;poke 0xc857 255
 poke 0xc840 30;poke 0xc841 2;poke 0xc801 96;poke 0xc800 0
 poke 0xc803 0;poke 0xc8d4 1;poke 0xc804 40
 set ::frames 0
 after frame sample
}
proc sample {} {
 incr ::frames
 if {[peek 0xc804]==0} {
  set f [open "$::out/result.txt" a]
  puts $f "$::phase $::frames [peek 0xc856]"
  close $f
  if {$::phase==0} {set ::phase 1;start 1} else {exit}
 } else {after frame sample}
}
file mkdir $out
set f [open "$out/result.txt" w];close $f
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 start 0
}
after time 10 {after frame ready}
after time 30 {exit 1}
