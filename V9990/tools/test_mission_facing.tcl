set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc capture {name} {
 global out
 set f [open "$out/$name.txt" w]
 puts $f "[peek 0xc801] [peek 0xc809] [peek 0xc803]";close $f
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/$name-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
}
after time 9.8 {poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc856 8;poke 0xc823 0;poke 0xc857 0}
after time 10 {keymatrixdown 8 16}
after time 10.25 {keymatrixup 8 16;poke 0xc819 0}
after time 10.38 {capture left;keymatrixdown 8 1}
after time 10.58 {capture left-kick;keymatrixup 8 1}
after time 11.3 {keymatrixdown 8 128}
after time 11.55 {keymatrixup 8 128;poke 0xc819 0}
after time 11.68 {capture right;keymatrixdown 8 1}
after time 11.88 {capture right-kick;keymatrixup 8 1;exit}
after time 15 {exit 1}
