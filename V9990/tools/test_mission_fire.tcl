set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc8a2] [peek 0xc856] [peek 0xc8b5] [peek 0xc801] [peek 0xc840] [peek 0xc8a0] [peek 0xc80a]"
 close $f
}
proc startfire {} {
 poke 0xc8a0 120;poke 0xc8a1 3;poke 0xc8d5 2
 poke 0xc8b2 191;poke 0xc8b3 1;poke 0xc8b4 0;poke 0xc8a2 1
}
after time 10 {
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8
 poke 0xc840 0;poke 0xc841 3;poke 0xc801 180;poke 0xc856 8;poke 0xc823 0
 startfire
}
after time 10.2 {record landed;set ::videosource GFX9000;screenshot -raw "$::out/fire.png"}
after time 12 {record expired;startfire}
after time 12.2 {poke 0xc840 0;poke 0xc841 3;poke 0xc801 96;poke 0xc80a 0;poke 0xc8d4 1}
after time 12.4 {record elevated;poke 0xc8d4 0}
after time 12.6 {record hit;exit}
after time 30 {exit 1}
