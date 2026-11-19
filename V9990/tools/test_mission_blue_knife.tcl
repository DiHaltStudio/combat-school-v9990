set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc watch {} {
 if {[peek 0xc8a2]==1 && [peek 0xc8d5]==1} {
  set f [open "$::out/result.txt" w]
  puts $f "[peek 0xc8f5] [peek 0xc8d5] [peek 0xc856]"
  close $f
  exit
 }
 after frame watch
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc840 100;poke 0xc841 2;poke 0xc801 96
 poke 0xc851 1;poke 0xc852 130;poke 0xc853 2;poke 0xc871 5
 poke 0xc8f5 1;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc891 5;poke 0xc8e0 1;poke 0xc8e9 5;poke 0xc8ad 13
 poke 0xc8a2 0;poke 0xc89c 159;poke 0xc856 8;poke 0xc857 255
 after frame watch
}
after time 10 {after frame ready}
after time 30 {exit 1}
