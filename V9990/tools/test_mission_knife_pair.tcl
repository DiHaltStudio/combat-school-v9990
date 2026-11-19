set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc930] [peek 0xc911] [peek 0xc921] [peek 0xc856] [peek 0xc8ad]"
 close $f
}
proc knife {} {
 if {[peek 0xc8a2]==1 && [peek 0xc8d5]==1} {record launched;exit}
 after frame knife
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc891 1;poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 5
 poke 0xc8ad 8;poke 0xc930 0;poke 0xc8a2 0;poke 0xc856 8;poke 0xc857 255
 poke 0xc840 2;poke 0xc841 3;poke 0xc801 96
 after time 0.2 {
  record before
  poke 0xc840 1
  after time 0.3 {
   record both
   set ::videosource GFX9000;screenshot -raw "$::out/both.png"
   after time 0.3 {
    record one
    poke 0xc840 68;poke 0xc841 2;poke 0xc801 96
    poke 0xc912 218;poke 0xc913 2;poke 0xc91c 159;poke 0xc8a2 0
    after frame knife
   }
  }
 }
}
after time 10 {after frame ready}
after time 30 {exit 1}
