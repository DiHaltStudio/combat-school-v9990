set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8;poke 0xc8da 1}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc set_camera {n} {
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8c1 5;poke 0xc8d0 1;poke 0xc8da 1;poke 0xc8ad 8;poke 0xc8a2 0;poke 0xc856 8;poke 0xc823 0;poke 0xc8e0 1;poke 0xc8e9 0;poke 0xc900 0;poke 0xc930 1;poke 0xc911 5;poke 0xc921 5;poke 0xc990 0
 poke 0xc840 [expr {$n&255}];poke 0xc841 [expr {($n>>8)&255}]
 poke 0xc800 0;poke 0xc801 96;poke 0xc803 0;poke 0xc804 0;poke 0xc819 0
}
proc capture {n} {
 global out
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/scroll-$n-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
}
after time 9.8 {poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc856 8;poke 0xc823 0;poke 0xc857 0}
after time 10 {set_camera 0}
after time 10.2 {capture 0;set_camera 1}
after time 10.4 {capture 1;set_camera 255}
after time 10.6 {capture 255;set_camera 256}
after time 10.8 {capture 256;set_camera 552}
after time 11.0 {capture 552;set_camera 767}
after time 11.2 {capture 767;set_camera 768}
after time 11.4 {capture 768;set_camera 1023}
after time 11.6 {capture 1023;set_camera 1024}
after time 11.8 {capture 1024;set_camera 1279}
after time 12.0 {capture 1279;set_camera 1280}
after time 12.2 {capture 1280;set_camera 1535}
after time 12.4 {capture 1535;set_camera 1536}
after time 12.6 {capture 1536;set_camera 256;keymatrixdown 8 16}
after time 13.1 {
 keymatrixup 8 16
 set ::camera_left [expr {[peek 0xc840]+256*[peek 0xc841]}]
 set ::player_left [peek 0xc801]
 keymatrixdown 8 128
}
after time 13.6 {
 keymatrixup 8 128
 set f [open "$out/movement.txt" w]
 puts $f "$::camera_left $::player_left [expr {[peek 0xc840]+256*[peek 0xc841]}] [peek 0xc801]";close $f
 exit
}
after time 18 {exit 1}
