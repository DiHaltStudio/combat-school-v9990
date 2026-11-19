set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc8e0] [peek 0xc8e9] [expr {[peek 0xc8ea]+256*[peek 0xc8eb]}] [peek 0xc8ad] [peek 0xc851] [peek 0xc871] [peek 0xc856]"
 close $f
}
proc watch_bottle {} {
 if {[peek 0xc8a2]==1 && [peek 0xc8d5]==2 && [peek 0xc8eb]==2} {record bottle;after time 0.08 {set ::videosource GFX9000;screenshot -raw "$::out/visible.png";exit};return}
 after frame watch_bottle
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc840 208;poke 0xc841 2;poke 0xc801 96
 poke 0xc8da 1;poke 0xc8e0 0;poke 0xc891 1;poke 0xc8ad 8;poke 0xc8ae 0
 poke 0xc857 255;poke 0xc8e2 52;poke 0xc8e3 3;poke 0xc930 1;poke 0xc911 5;poke 0xc921 5
 after time 0.2 {
  record alive
  poke 0xc840 187
  after time 0.3 {
   record spawned
   set ::videosource GFX9000;screenshot -raw "$::out/late.png"
   after time 0.4 {
    record later
    poke 0xc851 5;poke 0xc871 5;poke 0xc8ad 13
    poke 0xc840 234;poke 0xc841 1;poke 0xc801 96
    poke 0xc8dd 1;poke 0xc8a2 0;poke 0xc8dc 1;poke 0xc891 4
    after frame watch_bottle
   }
  }
 }
}
after time 10 {after frame ready}
after time 30 {exit 1}
