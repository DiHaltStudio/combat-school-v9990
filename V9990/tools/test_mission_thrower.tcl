set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc state {name} {
 global out
 set f [open "$out/$name.txt" w]
 set third [peek 0xc891]
 if {$third==5 && [peek 0xc851]!=5} {set third [peek 0xc851]}
 puts $f "$third [peek 0xc8a2] [peek 0xc8a3] [peek 0xc856] [peek 0xc823] [peek 0xc89c] [expr {[peek 0xc75c]+256*[peek 0xc75d]}]";close $f
}
proc capture {name} {
 global out
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/$name-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
}
proc watchthrow {} {
 if {[peek 0xc8a2]} {state thrown;capture thrown;return}
 after frame watchthrow
}
after time 10 {
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 0
 poke 0xc840 249;poke 0xc841 4;poke 0xc801 96
 poke 0xc856 8;poke 0xc823 0;poke 0xc8a2 0;poke 0xc890 0;poke 0xc8ac 0
}
after time 10.2 {state before;poke 0xc840 248}
after time 10.5 {state spawn}
after time 11 {
 poke 0xc840 0;poke 0xc841 4;poke 0xc801 96
 poke 0xc891 1;poke 0xc892 160;poke 0xc893 4;poke 0xc895 0
 poke 0xc89c 0;poke 0xc8a2 0;poke 0xc856 8;poke 0xc823 0
}
after time 11.25 {state first-room}
after time 11.3 {
 poke 0xc891 1;poke 0xc892 160;poke 0xc893 4;poke 0xc895 0
 poke 0xc89c 0;poke 0xc8a2 0;poke 0xc856 8;poke 0xc823 0
 poke 0xc8ac 1;poke 0xc89c 159
 after frame watchthrow
}
after time 13 {state hit}
after time 14 {
 # Start a projectile 16px left of the player while the latter is high in a jump.
 poke 0xc891 5;poke 0xc856 8;poke 0xc823 0
 poke 0xc804 20;poke 0xc80a 40
 poke 0xc8a0 104;poke 0xc8a1 4;poke 0xc8a3 0;poke 0xc8a2 1
 poke 0xc8b2 137;poke 0xc8b3 0;poke 0xc8b4 0
}
after time 14.15 {state jumped}
after time 15 {
 poke 0xc840 0;poke 0xc841 4;poke 0xc801 96;poke 0xc809 1
 poke 0xc891 1;poke 0xc892 72;poke 0xc893 4;poke 0xc898 0
 poke 0xc89c 255;poke 0xc8a2 0;poke 0xc856 8;poke 0xc823 0
 poke 0xc804 0;poke 0xc803 0;poke 0xc805 0;poke 0xc75c 0;poke 0xc75d 0
 keymatrixdown 8 1
}
after time 15.4 {keymatrixup 8 1;state orange-hit;exit}
after time 20 {exit 1}
