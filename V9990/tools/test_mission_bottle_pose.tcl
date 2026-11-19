set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc watch {} {
 if {[peek 0xc8a2]==1 && [peek 0xc8d5]==2} {
  after time 0.08 {
   set f [open "$::out/state.txt" w];puts $f "[peek 0xc8dc] [peek 0xc856]";close $f
   set ::videosource GFX9000;screenshot -raw "$::out/throw.png"
   foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
    set f [open "$::out/$part.bin" w];fconfigure $f -translation binary
    puts -nonewline $f [debug read_block $device 0 $size];close $f
   }
   exit
  }
  return
 }
 after frame watch
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 1;poke 0xc8ea 149;poke 0xc8eb 2
 poke 0xc930 1;poke 0xc911 5;poke 0xc8ad 8;poke 0xc900 1;poke 0xc990 0
 poke 0xc840 234;poke 0xc841 1;poke 0xc801 96;poke 0xc856 8;poke 0xc857 255;poke 0xc8dd 1
 poke 0xc8a2 0;poke 0xca02 0;poke 0xc8dc 1
 after frame watch
}
after time 10 {after frame ready}
after time 25 {exit 1}
