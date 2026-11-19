set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 if {[peek 0xc86f]!=0 || [peek 0xc8eb]!=2} {after frame [list record $name];return}
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc8e0] [peek 0xc8e9] [expr {[peek 0xc8ea]+256*[peek 0xc8eb]}] [peek 0xc856]"
 close $f
 if {$name eq "initial"} {
  poke 0xc801 140
  after time 1.2 {record moved}
 } elseif {$name eq "moved"} {
  poke 0xc8e9 4
  poke 0xc840 230;poke 0xc841 2;poke 0xc801 96
  after time 0.4 {poke 0xc840 170;poke 0xc841 2;after time 0.4 {record defeated}}
 } else {exit}
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 0;poke 0xc8e9 0;poke 0xc930 1;poke 0xc911 5;poke 0xc8ad 8
 poke 0xc900 0;poke 0xc990 31;poke 0xc941 0;poke 0xc951 0;poke 0xc961 0;poke 0xc971 0;poke 0xc981 0
 poke 0xc856 8;poke 0xc857 255;poke 0xc8dd 1;poke 0xc8dc 255
 poke 0xc840 187;poke 0xc841 2;poke 0xc801 96
 after frame [list record initial]
}
after time 10 {after frame ready}
after time 30 {exit 1}
