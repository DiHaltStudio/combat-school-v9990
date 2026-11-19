set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc set_camera {n} {
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8;poke 0xc8da 1;poke 0xc8a2 0;poke 0xc856 8;poke 0xc823 0
 set n [expr {$n+768}]
 poke 0xc840 [expr {$n&255}];poke 0xc841 [expr {($n>>8)&255}]
 poke 0xc800 0;poke 0xc801 96;poke 0xc803 0;poke 0xc804 0;poke 0xc819 0;poke 0xc809 0
}
proc capture {n} {
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$::out/$n-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
}
after time 9.8 {poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8;poke 0xc8da 1;poke 0xc856 8;poke 0xc823 0}
after time 10 {set_camera 350}
after time 10.3 {capture 350;set_camera 180}
after time 10.6 {capture 180;set_camera 150}
after time 10.9 {capture 150;set_camera 0}
after time 11.2 {capture 0;set_camera 230;keymatrixdown 8 16}
after time 13.2 {
 keymatrixup 8 16
 set f [open "$out/crossing.txt" w]
 puts $f "[expr {[peek 0xc840]+256*[peek 0xc841]-768}] [peek 0xc856]";close $f
 exit
}
after time 18 {exit 1}
