set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc8dd] [peek 0xc804] [peek 0xc856]"
 close $f
}
set ::checking_outside 1
proc outside_check {} {
 if {!$::checking_outside} {return}
 if {[peek 0xc8dd]!=0} {record outside_failed;exit 1}
 after frame outside_check
}
proc inside_check {} {
 if {[peek 0xc8dd]==1} {
  record caught
  keymatrixup 4 4
  after time 0.25 {
   keymatrixdown 4 4
   after time 0.12 {keymatrixup 4 4}
   after time 0.3 {record dropped;exit}
  }
  return
 }
 after frame inside_check
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 0;poke 0xc930 1;poke 0xc911 5;poke 0xc921 5
 poke 0xc8ad 8;poke 0xc900 0;poke 0xc990 0;poke 0xc856 8;poke 0xc857 255
 poke 0xc840 0;poke 0xc841 5;poke 0xc801 96;poke 0xc8d4 0;poke 0xc804 0;poke 0xc806 0
 keymatrixdown 4 4
 after time 0.1 {keymatrixup 4 4;after frame outside_check}
 after time 1.6 {
  set ::checking_outside 0
  record outside
  poke 0xc840 144;poke 0xc841 2;poke 0xc801 96;poke 0xc804 0;poke 0xc806 0;poke 0xc8d4 0
  keymatrixdown 4 4
  after frame inside_check
 }
}
after time 10 {after frame ready}
after time 30 {exit 1}
