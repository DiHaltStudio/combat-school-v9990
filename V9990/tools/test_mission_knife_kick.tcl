set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc state {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc8a2] [peek 0xc856]";close $f
}
proc setup {x direction facing type} {
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8
 poke 0xc840 0;poke 0xc841 4;poke 0xc801 96;poke 0xc809 $facing
 poke 0xc856 8;poke 0xc823 0;poke 0xc804 0;poke 0xc80a 0;poke 0xc803 20
 poke 0xc8a0 $x;poke 0xc8a1 4;poke 0xc8a3 $direction;poke 0xc8d5 $type
 poke 0xc8b2 128;poke 0xc8b3 0;poke 0xc8b4 0;poke 0xc8a2 1
}
after time 10 {setup 100 0 1 1}
after time 10.1 {state left;setup 140 1 0 1}
after time 10.2 {state right;setup 100 1 0 1}
after time 10.3 {state away;exit}
after time 30 {exit 1}
