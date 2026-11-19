set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::stage 0
proc capture {name} {
 global out
 set f [open "$out/$name.txt" w]
 puts $f "[peek 0xc823] [peek 0xc801] [expr {[peek 0xc852]+256*[peek 0xc853]}] [peek 0xc856] [expr {[peek 0xc801]+[peek 0xc840]+256*[peek 0xc841]}]";close $f
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/$name-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
}
proc watch {} {
 set t [peek 0xc823]
 if {$::stage==0 && $t>0} {
  set ::stage 1;keymatrixdown 8 128
 } elseif {$::stage==1 && $t>0 && $t<=48} {
  set ::stage 2;capture held
 } elseif {$::stage==2 && $t>0 && $t<=20} {
  set ::stage 3;capture fallen
 } elseif {$::stage==3 && $t==0} {
  set ::stage 4;capture recovered
  after time 0.3 {capture movement;keymatrixup 8 128;exit}
  return
 }
 after frame watch
}
after time 10 {
 set facing $::env(MISSION_GRAB_FACING)
 poke 0xc840 0;poke 0xc841 4;poke 0xc801 96;poke 0xc809 $facing
 poke 0xc852 [expr {$facing==1?80:112}];poke 0xc853 4;poke 0xc851 1;poke 0xc871 5;poke 0xc891 5
 poke 0xc856 8;poke 0xc857 0;poke 0xc823 0;poke 0xc803 0;poke 0xc804 0
 after frame watch
}
after time 20 {exit 1}
