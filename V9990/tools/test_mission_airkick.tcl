set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc capture {name} {
 global out
 set f [open "$out/$name.txt" w]
 puts $f "[peek 0xc801] [peek 0xc809] [peek 0xc803] [peek 0xc804] [peek 0xc80a]";close $f
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/$name-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
 set ::videosource GFX9000
 screenshot -raw "$out/$name.png"
}
after time 9.8 {poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc856 8;poke 0xc823 0;poke 0xc857 0}
after time 10 {keymatrixdown 8 128}
after time 10.25 {keymatrixdown 4 4}
after time 10.33 {keymatrixup 4 4}
after time 10.42 {keymatrixdown 8 1}
after time 10.55 {capture right;keymatrixup 8 1;keymatrixup 8 128}
after time 12 {keymatrixdown 8 16}
after time 12.25 {keymatrixdown 4 4}
after time 12.33 {keymatrixup 4 4}
after time 12.42 {keymatrixdown 8 1}
after time 12.55 {capture left;keymatrixup 8 1;keymatrixup 8 16;exit}
after time 16 {exit 1}
