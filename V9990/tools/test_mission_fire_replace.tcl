set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc check {} {
 if {[peek 0xca02]==2 && [peek 0xc8a2]==0 && [peek 0xc900]==2} {
  set f [open "$::out/result.txt" w]
  puts $f "[peek 0xc8a2] [peek 0xca02] [peek 0xc900] [peek 0xc856]"
  close $f
  after time 2 {
   set f [open "$::out/sustained.txt" w]
   puts $f "[peek 0xca02] [peek 0xca08] [peek 0xc900] [peek 0xc856]"
   close $f
   exit
  }
  return
 }
 after frame check
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 0;poke 0xc930 1;poke 0xc911 5;poke 0xc8ad 8
 poke 0xc840 8;poke 0xc841 2;poke 0xc801 96;poke 0xc8dd 1;poke 0xc856 8
 poke 0xc900 1;poke 0xc8a0 88;poke 0xc8a1 2;poke 0xc8a2 2;poke 0xc8b5 200;poke 0xc8d5 2
 poke 0xca00 130;poke 0xca01 2;poke 0xca02 1;poke 0xca03 0;poke 0xca05 190;poke 0xca06 2;poke 0xca07 0;poke 0xca09 2
 after frame check
}
after time 10 {after frame ready}
after time 25 {exit 1}
