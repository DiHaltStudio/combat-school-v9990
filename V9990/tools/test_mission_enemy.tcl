set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc setup {screen_x facing} {
 poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8;poke 0xc8da 1;poke 0xc8a2 0
 set enemy [expr {1024+$screen_x}]
 poke 0xc840 0;poke 0xc841 4
 poke 0xc800 0;poke 0xc801 96;poke 0xc809 $facing
 poke 0xc852 [expr {$enemy&255}];poke 0xc853 [expr {$enemy>>8}]
 poke 0xc851 1;poke 0xc855 0;poke 0xc856 8;poke 0xc857 255
 poke 0xc871 5;poke 0xc891 5
 poke 0xc858 0;poke 0xc823 0;poke 0xc803 0;poke 0xc804 0
 poke 0xc805 0;poke 0xc806 0;poke 0xc81e 0
 poke 0xc75c 0;poke 0xc75d 0;poke 0xc75e 0
}
proc state {name} {
 global out
 set f [open "$out/$name.txt" w]
 puts $f "[peek 0xc851] [peek 0xc856] [expr {[peek 0xc75c]+256*[peek 0xc75d]}] [peek 0xc857] [peek 0xc85b] [peek 0xc823] [peek 0xc818]";close $f
}
proc capture {name} {
 global out
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/$name-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
}
proc restart_when_ready {} {
 if {[peek 0xc856]==0 && [peek 0xc823]==0 && [peek 0xc818]==1} {
  after time 0.3 {keymatrixdown 8 1}
  after time 0.7 {keymatrixup 8 1;after frame watch_restart}
 } else {after frame restart_when_ready}
}
proc watch_restart {} {
 if {[peek 0xc856]==8} {state restarted;exit}
 after frame watch_restart
}
after time 10 {setup 72 1;keymatrixdown 8 1}
after time 10.35 {
 keymatrixup 8 1;state hit
 capture hit
 set ::videosource GFX9000;screenshot -raw "$out/hit.png"
}
after time 11 {setup 72 0;keymatrixdown 8 1}
after time 11.35 {keymatrixup 8 1;state wrong-facing}
after time 12 {setup 0 1;keymatrixdown 8 1}
after time 12.35 {keymatrixup 8 1;state distant}
after time 13 {setup 80 1;poke 0xc857 0}
after time 13.2 {state contact;capture contact;set ::videosource GFX9000;screenshot -raw "$out/contact.png"}
after time 13.5 {state contact-held}
after time 14 {setup 72 1;poke 0xc804 25;poke 0xc80a 30;keymatrixdown 8 1}
after time 14.35 {keymatrixup 8 1;state air-hit}
after time 15 {setup 80 1;poke 0xc856 1;poke 0xc857 0}
after time 15.2 {state game-over}
after time 15.25 {after frame restart_when_ready}
after time 60 {exit 1}
