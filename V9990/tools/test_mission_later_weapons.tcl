set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc8a2] [peek 0xc8d5] [peek 0xc856]"
 close $f
}
proc watch_bottle {} {
 if {[peek 0xc8a2]==1 && [peek 0xc8d5]==2} {
  record bottle
  exit
 }
 after frame watch_bottle
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 0;poke 0xc930 1;poke 0xc911 5;poke 0xc921 5
 poke 0xc8ad 8;poke 0xc900 1;poke 0xc990 15;poke 0xc857 255;poke 0xc8dd 1
 poke 0xc951 0;poke 0xc961 0;poke 0xc971 0;poke 0xc981 0
 poke 0xc840 94;poke 0xc841 1;poke 0xc801 96
 poke 0xc941 1;poke 0xc942 254;poke 0xc943 1;poke 0xc94d 0;poke 0xc8a2 0
 after frame watch_bottle
}
after time 10 {after frame ready}
after time 30 {exit 1}
