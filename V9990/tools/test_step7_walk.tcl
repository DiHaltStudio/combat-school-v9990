set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
proc xpos {} {expr {[peek 0xc800]+256*[peek 0xc801]}}
proc snap {name} {
 global out
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/$name-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
}
after time 10 {poke 0xc813 170;poke 0xc80d 0;poke 0xc80e 255;poke 0xc822 0;poke 0xc823 0;keymatrixdown 8 128}
after time 10.1 {set ::x1 [peek 0xc801];set ::w1 [peek 0xc819];set ::cw1 [peek 0xc81a];set ::cpu1 [peek 0xc813];snap walk1}
after time 10.3 {set ::x2 [peek 0xc801];set ::w2 [peek 0xc819];set ::cw2 [peek 0xc81a];set ::cpu2 [peek 0xc813];snap walk2}
after time 10.5 {poke 0xc803 15;set ::before [xpos]}
after time 10.62 {set ::after [xpos];set ::attack [peek 0xc803];keymatrixup 8 128;set f [open "$out/walk.txt" w];puts $f "$::x1 $::x2 $::w1 $::w2 $::cw1 $::cw2 $::before $::after $::attack $::cpu1 $::cpu2";close $f;exit}
after time 14 {exit 1}
