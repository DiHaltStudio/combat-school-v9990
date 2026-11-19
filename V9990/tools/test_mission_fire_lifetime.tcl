set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc save {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc8a2] [peek 0xc8b5] [peek 0xc900] [peek 0xc856]"
 close $f
}
proc wait_fire {} {
 if {[peek 0xc8a2]==2} {
  save ignited
  after time 2 {save sustained;exit}
  return
 }
 after frame wait_fire
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 0;poke 0xc930 1;poke 0xc911 5;poke 0xc8ad 8
 poke 0xc900 1;poke 0xc990 0;poke 0xc856 8;poke 0xc8dd 1;poke 0xca02 0
 poke 0xc840 72;poke 0xc841 3;poke 0xc801 96
 poke 0xc8a0 188;poke 0xc8a1 3;poke 0xc8a2 1;poke 0xc8a3 0;poke 0xc8b2 190;poke 0xc8b3 2;poke 0xc8b4 0;poke 0xc8d5 2
 after frame wait_fire
}
after time 10 {after frame ready}
after time 25 {exit 1}
