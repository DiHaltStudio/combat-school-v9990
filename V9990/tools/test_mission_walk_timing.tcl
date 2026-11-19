# Loop timing on a real walk: from the start through the doorway to the
# industrial area, holding left and kicking every 40 loops, enemies active.
# MISSION_START_CAM starts at another camera position instead.
# The player is kept alive (health and recovery); nothing else is changed.
# timing.txt: loop, emulated time, camera, player screen X, and the time at
# which the CPU and the V9990 finished drawing the previous loop
# (MISSION_IDLE: first pass through loop.wait_start), 0 if not measured.
set throttle off
catch {set vsync off}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::n -1
set ::log [open "$out/timing.txt" w]
proc sample {} {
 if {$::n<0} {
  if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {debug cont;return}
  set ::n 0
  # MISSION_START_CAM: start further on (camera teleport, enemies as they are).
  if {[info exists ::env(MISSION_START_CAM)]} {
   set c $::env(MISSION_START_CAM)
   poke 0xc840 [expr {$c&255}];poke 0xc841 [expr {$c>>8}];poke 0xc801 96
   # The earlier encounters are over by then: retire their actors and
   # latches as test_mission_doorway.tcl does.
   poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8ad 8
   poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc930 1;poke 0xc911 5;poke 0xc921 5
  }
  keymatrixdown 8 16
 }
 incr ::n
 poke 0xc856 8;poke 0xc857 40
 if {$::n%40==0} {keymatrixdown 8 1} elseif {$::n%40==3} {keymatrixup 8 1}
 set cam [expr {[peek 0xc840]+256*[peek 0xc841]}]
 puts $::log "$::n [machine_info time] $cam [peek 0xc801] $::idle"
 set ::idle 0
 if {$::n>=$::env(MISSION_LOOPS)} {close $::log;exit;return}
 debug cont
}
set ::idle 0
proc idle {} {
 if {$::idle==0} {set ::idle [machine_info time]}
 debug cont
}
debug set_bp $::env(MISSION_LOOP) {} sample
if {[info exists ::env(MISSION_IDLE)]} {debug set_bp $::env(MISSION_IDLE) {} idle}
after time 120 {exit 1}
