set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc save {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc8a2] [peek 0xc8d5] [peek 0xc8b5] [peek 0xca02] [peek 0xca09] [expr {[peek 0xca00]+256*[peek 0xca01]}] [peek 0xc856]"
 close $f
}
proc wait_knife {} {
 if {[peek 0xca02]==1 && [peek 0xca09]==1} {
  save both
  after time 0.12 {save moved;exit}
  return
 }
 after frame wait_knife
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 0;poke 0xc930 1;poke 0xc911 1;poke 0xc921 0
 poke 0xc8ad 8;poke 0xc900 0;poke 0xc990 0;poke 0xc857 255;poke 0xc8dd 1
 poke 0xc840 68;poke 0xc841 2;poke 0xc801 96
 poke 0xc912 218;poke 0xc913 2;poke 0xc91c 159
 poke 0xc8a0 120;poke 0xc8a1 2;poke 0xc8a2 2;poke 0xc8d5 2;poke 0xc8b5 200;poke 0xca02 0
 after frame wait_knife
}
after time 10 {after frame ready}
after time 30 {exit 1}
