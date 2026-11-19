set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc capture {name} {
 global out
 foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$out/$name-$part.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
}
proc thirdstate {} {
 set s [peek 0xc891]
 if {$s==5 && [peek 0xc851]!=5} {return [list [peek 0xc851] [peek 0xc854]]}
 return [list $s [peek 0xc894]]
}
set ::fall_frames 0
set ::fall_stage 0
proc watchfall {} {
 incr ::fall_frames
 lassign [thirdstate] state timer
 if {$::fall_stage==0 && $state==2 && $timer<=4} {
  capture hit;set ::fall_stage 1
 } elseif {$::fall_stage==1 && $state==3 && $timer<=10 && $timer>=8} {
  capture knee;set ::fall_stage 2
 } elseif {$::fall_stage==2 && $state==3 && $timer<=4 && $timer>0} {
  capture hands;set ::fall_stage 3
 } elseif {$::fall_stage==3 && $state==4} {
  set ::fall_stage 4
  set f [open "$::out/timing.txt" w];puts $f $::fall_frames;close $f
  after time 0.15 {capture down}
  after time 1.5 {
   set f [open "$::out/persist.txt" w];puts $f [lindex [thirdstate] 0];close $f;exit
  }
  return
 }
 after frame watchfall
}
after time 10 {
 poke 0xc851 5;poke 0xc871 5;poke 0xc856 8;poke 0xc823 0
 poke 0xc840 0;poke 0xc841 4;poke 0xc801 96
 poke 0xc891 2;poke 0xc892 40;poke 0xc893 4;poke 0xc894 8;poke 0xc89a $::env(MISSION_ORANGE_FACING)
 after frame watchfall
}
after time 20 {exit 1}
