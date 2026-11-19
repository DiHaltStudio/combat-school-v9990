set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::frame 0
set ::started 0
set ::apex_saved 0
set ::trace [open "$out/arc.txt" w]
proc watch_arc {} {
 set active [peek 0xc8a2]
 if {$active==1 && [peek 0xc8d5]==2} {
  set ::started 1
  incr ::frame
  puts $::trace "$::frame [expr {[peek 0xc8a0]+256*[peek 0xc8a1]}] [peek 0xc8b2] [peek 0xc856]"
  if {!$::apex_saved && [peek 0xc8b2]<=135} {
   set ::apex_saved 1
   set ::videosource GFX9000
   screenshot -raw "$::out/apex.png"
  }
  if {$::frame==12} {poke 0xc801 120}
 } elseif {$::started && $active==2} {
  puts $::trace "land [expr {[peek 0xc8a0]+256*[peek 0xc8a1]}] [peek 0xc8b2] [peek 0xc856]"
  close $::trace
  after time 0.08 {set ::videosource GFX9000;screenshot -raw "$::out/land.png";exit}
  return
 } elseif {$::started && (!$active || [peek 0xc856]==0)} {
  puts $::trace "lost $active [peek 0xc856]"
  close $::trace
  exit 1
 }
 after frame watch_arc
}
proc setup {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame setup;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8
 poke 0xc840 72;poke 0xc841 3;poke 0xc801 96;poke 0xc856 8;poke 0xc823 0
 poke 0xc8da 0;poke 0xc8a2 0
 after frame watch_arc
}
after time 10 {after frame setup}
after time 30 {close $::trace;exit 1}
