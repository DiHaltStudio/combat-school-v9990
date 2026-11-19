set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[expr {[peek 0xc840]+256*[peek 0xc841]+[peek 0xc801]+32}] [peek 0xc8dd] [peek 0xc856]"
 close $f
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 0;poke 0xc930 1;poke 0xc911 5;poke 0xc8ad 8;poke 0xc900 0
 poke 0xc840 44;poke 0xc841 2;poke 0xc801 138;poke 0xc800 0;poke 0xc856 8;poke 0xc857 255
 poke 0xc8dd 0;poke 0xc804 0;poke 0xc8d4 0
 keymatrixdown 8 16
 after time 1.2 {
  record walking
  poke 0xc8d4 1;poke 0xc804 40;poke 0xc808 2
  after time 1.4 {
   record jumping
   poke 0xc8dd 1;poke 0xc804 0;poke 0xc806 0;poke 0xc8d4 0
   after time 2 {
    record hanging
    keymatrixup 8 16
    exit
   }
  }
 }
}
after time 10 {after frame ready}
after time 30 {exit 1}
