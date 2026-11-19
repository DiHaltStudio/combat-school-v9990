set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::phase 0
proc start {n} {
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 [expr {$n==0?0:1}]
 poke 0xc8ea 149;poke 0xc8eb 2;poke 0xc8ed 0;poke 0xc8dc 255
 poke 0xc930 1;poke 0xc911 5;poke 0xc8ad 8;poke 0xc900 [expr {$n==0?0:1}];poke 0xc990 0
 poke 0xc941 0;poke 0xc8a2 0;poke 0xca02 0;poke 0xc856 8;poke 0xc823 0;poke 0xc857 255
 poke 0xc840 50;poke 0xc841 2;poke 0xc801 96;poke 0xc800 0
 poke 0xc803 0;poke 0xc808 2;poke 0xc8d4 2;poke 0xc8dd 0;poke 0xc804 32;poke 0xc806 0
 if {$n>=2} {
  poke 0xc8a0 108;poke 0xc8a1 2;poke 0xc8a2 1;poke 0xc8a3 1
  poke 0xc8b2 125;poke 0xc8b3 255;poke 0xc8b4 0;poke 0xc8d5 2
 }
 if {$n==3} {
  # A recently defeated blue attacker remains visible beside the box.
  poke 0xc911 4;poke 0xc912 218;poke 0xc913 2;poke 0xc914 250
  poke 0xc891 4;poke 0xc892 52;poke 0xc893 3;poke 0xc894 250
 }
 set ::frames 0
 if {$n==3} {
  # Let the game retire old bodies before starting the measured jump.
  poke 0xc804 0
  after frame wait_retired
 } else {after frame sample}
}
proc wait_retired {} {
 if {[peek 0xc911]!=5 || [peek 0xc891]!=5 || [peek 0xc86f]!=0} {after frame wait_retired;return}
 poke 0xc8d4 2;poke 0xc804 32;poke 0xc808 2;poke 0xc8dd 0
 set ::frames 0
 after frame sample
}
proc sample {} {
 incr ::frames
 if {[peek 0xc8dd]==1} {
  set f [open "$::out/result.txt" a]
  puts $f "$::phase $::frames [peek 0xc856]"
  close $f
  if {$::phase<3} {incr ::phase;after time 0.3 [list start $::phase]} else {exit}
 } else {after frame sample}
}
set f [open "$out/result.txt" w];close $f
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 start 0
}
after time 10 {after frame ready}
after time 30 {exit 1}
