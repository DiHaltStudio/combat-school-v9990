set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc900] [peek 0xc856] [peek 0xc8dd] [peek 0xc8e9]"
 close $f
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 0;poke 0xc8e9 1;poke 0xc8ad 11;poke 0xc8a2 0
 poke 0xc840 208;poke 0xc841 2;poke 0xc801 96;poke 0xc856 8;poke 0xc900 0
 poke 0xc8dd 1;poke 0xc8d4 0;poke 0xc804 0;poke 0xc806 0
 after time 0.2 {
  record before
  poke 0xc840 8;poke 0xc841 2;poke 0xc8e0 1;poke 0xc8e9 1
  after time 0.4 {
   record hanging
   set ::videosource GFX9000;screenshot -raw "$::out/fire.png"
   poke 0xc801 72;poke 0xc8dd 0;poke 0xc804 0;poke 0xc80a 0;poke 0xc857 0
   after time 0.3 {
    record ground
    poke 0xc856 8;poke 0xc823 0;poke 0xc857 0;poke 0xc8dd 0;poke 0xc8d4 0
    poke 0xc804 0;poke 0xc80a 0;poke 0xc990 7
    poke 0xc840 94;poke 0xc841 1;poke 0xc801 91
    after time 0.3 {record third;exit}
   }
  }
 }
}
after time 10 {after frame ready}
after time 30 {exit 1}
