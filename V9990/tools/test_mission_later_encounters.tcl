set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc990] [peek 0xc941] [peek 0xc951] [peek 0xc961] [peek 0xc971] [peek 0xc981] [peek 0xc856]"
 close $f
}
proc camera {x} {poke 0xc840 [expr {$x & 255}];poke 0xc841 [expr {$x >> 8}];poke 0xc801 96}
proc defeat {} {
 if {[peek 0xc86f]!=0 || [peek 0xc941]!=1} {after frame defeat;return}
 poke 0xc941 4
 camera 229
 after time 1 {record defeated;camera 529;after time 0.5 {camera 200;after time 0.5 {record returned;exit}}}
}
proc check_spawn {} {
 if {[peek 0xc86f]!=0 || [peek 0xc941]!=1} {after frame check_spawn;return}
 record first
 after time 0.3 {defeat}
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5
 poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 4;poke 0xc930 1;poke 0xc911 5;poke 0xc921 5
 poke 0xc8ad 8;poke 0xc900 1;poke 0xc990 0;poke 0xc8dd 1;poke 0xc857 255
 camera 531
 after time 0.2 {record before;camera 529;after frame check_spawn}
}
after time 10 {after frame ready}
after time 30 {exit 1}
