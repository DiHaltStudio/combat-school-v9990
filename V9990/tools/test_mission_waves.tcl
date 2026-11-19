set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc state {name} {
 global out
 set f [open "$out/$name.txt" w]
 puts $f "[peek 0xc8ad] [peek 0xc851] [peek 0xc871] [peek 0xc856] [expr {[peek 0xc852]+256*[peek 0xc853]}] [expr {[peek 0xc872]+256*[peek 0xc873]}]";close $f
}
proc capture {name} {
 global out
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/$name-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
}
after time 10 {
 poke 0xc891 5;poke 0xc851 5;poke 0xc871 5
 poke 0xc840 10;poke 0xc841 5;poke 0xc801 96;poke 0xc8da 1
 poke 0xc856 8;poke 0xc857 255;poke 0xc823 0;poke 0xc8ad 0;poke 0xc8ae 0
}
after time 10.2 {state before;poke 0xc840 8}
after time 10.5 {state left}
after time 11 {poke 0xc851 5;poke 0xc871 5;poke 0xc8ae 0}
after time 11.3 {state no-repeat;poke 0xc840 200;poke 0xc841 4}
after time 11.6 {state right}
after time 11.7 {poke 0xc840 10;poke 0xc841 5;poke 0xc8ae 0}
after time 11.9 {state backtrack}
after time 12 {
 poke 0xc851 5;poke 0xc871 5;poke 0xc8ae 0
 poke 0xc840 0;poke 0xc841 3;poke 0xc801 20
}
after time 12.3 {state safe-side}
after time 13 {
 poke 0xc851 5;poke 0xc871 5;poke 0xc8ae 0;poke 0xc856 0;poke 0xc823 200
 state pre-dead
}
after time 13.3 {state dead}
after time 14 {poke 0xc856 8;poke 0xc823 0;poke 0xc8ad 8;poke 0xc75c 208;poke 0xc75d 7}
after time 14.5 {capture score2000}
after time 15 {poke 0xc75c 124;poke 0xc75d 21}
after time 15.5 {capture score5500;poke 0xc75c 112;poke 0xc75d 23}
after time 16 {capture score6000;exit}
after time 22 {exit 1}
