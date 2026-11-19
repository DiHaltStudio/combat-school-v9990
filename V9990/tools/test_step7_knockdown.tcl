set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
proc capture {name} {
 global out
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/$name-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
}
after time 10 {poke 0xc823 0;poke 0xc822 0;poke 0xc801 70;poke 0xc809 0;poke 0xc813 120;poke 0xc811 0;poke 0xc80d 0;poke 0xc814 1;poke 0xc828 20}
after time 10.25 {capture instructor-down;poke 0xc814 2;poke 0xc828 20;poke 0xc823 0}
after time 10.5 {capture player-down;exit}
after time 14 {exit 1}
