set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::mission_walk_samples {}
proc sample {} {
 set phase [expr {([peek 0xfc9e]>>3)&3}]
 if {[peek 0xc819]>0 && [lsearch -exact $::mission_walk_samples $phase]<0} {
  lappend ::mission_walk_samples $phase
  foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
   set f [open "$::out/$phase-$part.bin" w];fconfigure $f -translation binary
   puts -nonewline $f [debug read_block $device 0 $size];close $f
  }
 }
 if {[llength $::mission_walk_samples]==4} {exit}
 after frame sample
}
proc start_when_ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {
  after frame start_when_ready
  return
 }
 poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5
 poke 0xc840 0;poke 0xc841 4;poke 0xc801 96;poke 0xc856 8
 keymatrixdown 8 128
 after frame sample
}
after time 1 {after frame start_when_ready}
after time 40 {exit 1}
