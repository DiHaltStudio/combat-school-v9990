set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
after time 9.8 {poke 0xc891 5}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc setup_positions {} {
 poke 0xc840 0;poke 0xc841 4;poke 0xc800 0;poke 0xc801 96
 poke 0xc852 72;poke 0xc853 4;poke 0xc851 1;poke 0xc855 0;poke 0xc858 0
 poke 0xc872 120;poke 0xc873 4;poke 0xc871 1;poke 0xc875 0;poke 0xc878 0
 poke 0xc856 8;poke 0xc857 255;poke 0xc823 0
 poke 0xc803 0;poke 0xc804 0;poke 0xc805 0;poke 0xc81e 0
 poke 0xc75c 0;poke 0xc75d 0;poke 0xc75e 0
}
proc state {name} {
 global out
 set f [open "$out/$name.txt" w]
 puts $f "[peek 0xc851] [peek 0xc871] [expr {[peek 0xc75c]+256*[peek 0xc75d]}] [peek 0xc856]";close $f
}
after time 10 {setup_positions;poke 0xc809 1;keymatrixdown 8 1}
after time 10.35 {keymatrixup 8 1;state left-hit}
after time 11.3 {
 poke 0xc809 0;poke 0xc803 0;poke 0xc805 0;poke 0xc81e 0
 poke 0xc872 120;poke 0xc873 4;poke 0xc871 1;poke 0xc878 0
 keymatrixdown 8 1
}
after time 11.65 {
 keymatrixup 8 1;state right-hit
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/score-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
 exit
}
after time 15 {exit 1}
