set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc setup {x hp invuln} {
 poke 0xc840 0;poke 0xc841 4;poke 0xc801 96;poke 0xc809 1
 poke 0xc852 $x;poke 0xc853 4;poke 0xc851 1;poke 0xc871 5;poke 0xc891 5
 poke 0xc855 0;poke 0xc856 $hp;poke 0xc857 $invuln
 poke 0xc858 0;poke 0xc820 0;poke 0xc823 0;poke 0xc803 0;poke 0xc804 0
 poke 0xc805 0;poke 0xc806 0;poke 0xc81e 0
}
proc watch {name} {
 if {[peek 0xc820]>0} {after frame [list after frame [list capture $name]];return}
 after frame [list watch $name]
}
proc capture {name} {
 global out
 set f [open "$out/$name.txt" w]
 puts $f "[peek 0xc820] [peek 0xc821] [expr {[peek 0xc825]+256*[peek 0xc826]-[peek 0xc840]-256*[peek 0xc841]}]";close $f
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/$name-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
 if {$name eq "player-hit"} {exit}
}
after time 10 {setup 72 8 255;keymatrixdown 8 1;after frame [list watch enemy-hit]}
after time 10.5 {keymatrixup 8 1}
after time 11 {setup 80 8 0;after frame [list watch player-hit]}
after time 15 {exit 1}
