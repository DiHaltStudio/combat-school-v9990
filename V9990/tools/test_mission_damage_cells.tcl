set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::damage 0
proc capture_damage {} {
 global out
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/damage-$::damage-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
 if {$::damage==8} {exit;return}
 incr ::damage
 poke 0xc856 [expr {8-$::damage}]
 after time 0.25 capture_damage
}
after time 9.8 {poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc856 8;poke 0xc823 0;poke 0xc857 0}
after time 10.1 capture_damage
after time 15 {exit 1}
