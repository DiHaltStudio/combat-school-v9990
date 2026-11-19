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
after time 10 {poke 0xc813 165;poke 0xc80e 255;poke 0xc80b 8;poke 0xc80c 8}
after time 10.2 {capture empty;poke 0xc80b 7;poke 0xc80c 7}
after time 10.4 {capture one;poke 0xc80b 6;poke 0xc80c 6}
after time 10.6 {capture two;exit}
after time 14 {exit 1}
