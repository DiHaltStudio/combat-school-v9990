# Count display frames for the same jump, including an offset camera and damage.
set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
after time 9.8 {poke 0xc891 5}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::phase 0
proc startcase {n} {
 poke 0xc891 5;poke 0xc8a2 0
 poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc840 [expr {$n==2?1:0}];poke 0xc841 4;poke 0xc801 96
 poke 0xc856 [expr {$n==2?1:8}];poke 0xc823 0;poke 0xc857 255
 poke 0xc852 [expr {$n==2?73:72}];poke 0xc853 4
 poke 0xc872 [expr {$n==2?121:120}];poke 0xc873 4
 set state [expr {$n==0?5:($n==2?1:4)}]
 poke 0xc851 $state;poke 0xc871 $state
 if {$n==3} {
  poke 0xc891 1;poke 0xc892 176;poke 0xc893 4
  poke 0xc89c 255;poke 0xc8a2 0
 }
 if {$n==4} {
  poke 0xc840 200;poke 0xc841 3
  poke 0xc852 16;poke 0xc853 4;poke 0xc872 64;poke 0xc873 4
  poke 0xc8c1 1;poke 0xc8c2 200;poke 0xc8c3 3
  poke 0xc89c 255;poke 0xc8a2 0
 }
 poke 0xc854 250;poke 0xc874 250;poke 0xc804 40;poke 0xc803 20
 set ::frames 0
 after frame sample
}
proc sample {} {
 incr ::frames
 if {[peek 0xc804]==0} {
  set f [open "$::out/performance.txt" a]
  puts $f "$::phase $::frames"
  close $f
  if {$::phase<4} {incr ::phase;startcase $::phase} else {exit}
 } else {after frame sample}
}
set f [open "$out/performance.txt" w];close $f
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc8ad 8
 startcase 0
}
after time 10 {after frame ready}
after time 20 {exit 1}
