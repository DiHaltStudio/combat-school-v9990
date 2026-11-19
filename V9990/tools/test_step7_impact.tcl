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
proc common {} {
 poke 0xc800 0;poke 0xc801 70;poke 0xc809 0;poke 0xc813 100
 poke 0xc80b 8;poke 0xc80c 8;poke 0xc80d 0;poke 0xc80e 200
 poke 0xc80f 0;poke 0xc810 0;poke 0xc814 0;poke 0xc804 0
 poke 0xc820 0;poke 0xc821 0;poke 0xc822 0;poke 0xc823 0;poke 0xc826 0;poke 0xc827 0;poke 0xc81e 0;poke 0xc840 0;poke 0xc841 0;poke 0xc842 0
}
after time 10 {common;poke 0xc803 18}
after time 10.08 {set ::orange [peek 0xc820];set ::orange_cpu [peek 0xc813];set ::cpu_hp [peek 0xc80c];capture orange;set ::videosource GFX9000;screenshot -raw "$out/orange.png"}
after time 10.35 {set ::cpu_end [peek 0xc813];set ::orange_end [peek 0xc820]}
after time 11 {common;poke 0xc803 0;poke 0xc80d 24}
after time 11.08 {set ::violet [peek 0xc821];set ::violet_player [peek 0xc801];set ::player_hp [peek 0xc80b];capture violet;set ::videosource GFX9000;screenshot -raw "$out/violet.png"}
after time 11.35 {set ::player_end [peek 0xc801];set ::violet_end [peek 0xc821]}
after time 12 {common;poke 0xc801 123;poke 0xc809 1;poke 0xc803 18}
after time 12.1 {set ::cpu_other [peek 0xc813]}
after time 13 {common;poke 0xc801 123;poke 0xc809 1;poke 0xc803 0;poke 0xc80d 24}
after time 13.3 {set ::player_other [peek 0xc801];set f [open "$out/impact.txt" w];puts $f "$::orange $::orange_cpu $::cpu_hp $::cpu_end $::orange_end $::violet $::violet_player $::player_hp $::player_end $::violet_end $::cpu_other $::player_other";close $f;exit}
after time 14 {exit 1}
