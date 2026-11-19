set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 set f [open "$::out/$name.txt" w]
 set x [expr {[peek 0xc840]+256*[peek 0xc841]+[peek 0xc801]+32-512}]
 puts $f "$x [peek 0xc8d4] [peek 0xc804] [peek 0xc856]";close $f
}
proc watch_top {} {
 if {[peek 0xc8d4]==2} {
  keymatrixup 8 16
  after time 0.1 {record atop;set ::videosource GFX9000;screenshot -raw "$::out/atop.png"}
  return
 }
 after frame watch_top
}
proc watch_top_left {} {
 if {[peek 0xc8d4]==2} {
  keymatrixup 8 128
  after time 0.1 {record atop-left;keymatrixdown 8 128}
  after time 1.5 {keymatrixup 8 128;record exit-right;exit}
  return
 }
 after frame watch_top_left
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8;poke 0xc8a2 0;poke 0xc8da 1
 poke 0xc840 0;poke 0xc841 2;poke 0xc800 0;poke 0xc801 200
 poke 0xc856 8;poke 0xc823 0;poke 0xc804 0;poke 0xc806 0;poke 0xc8d4 0
 keymatrixdown 8 16
 after time 1.5 {record blocked-right;keymatrixdown 4 4;after frame watch_top}
 after time 1.65 {keymatrixup 4 4}
 after time 3.5 {
  poke 0xc840 0;poke 0xc841 2;poke 0xc800 0;poke 0xc801 105
  poke 0xc804 0;poke 0xc806 0;poke 0xc8d4 0
  keymatrixdown 8 128
 }
 after time 4.8 {record blocked-left;keymatrixdown 4 4;after frame watch_top_left}
 after time 4.95 {keymatrixup 4 4}
}
after time 10 {after frame ready}
after time 40 {exit 1}
