# Chain assailant entry as in the arcade (tools/mame_mission_chain_capture.lua):
# from camera 300, earlier encounters retired, the player walks left. The
# assailant appears when the camera passes 272, outside the left edge, walks
# in, and the camera stays at 258 until it is down; then it moves on.
# log.txt: loop, camera, chain state, chain origin.
set throttle off
catch {set vsync off}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::n -1
set ::log [open "$out/log.txt" w]
proc word {addr value} {poke $addr [expr {$value&255}];poke [expr {$addr+1}] [expr {$value>>8}]}
proc sample {} {
 if {$::n<0} {
  if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {debug cont;return}
  set ::n 0
  foreach addr {0xc851 0xc871 0xc891 0xc8c1 0xc8e1 0xc911 0xc921 0xc941 0xc951 0xc961} {poke $addr 5}
  poke 0xc8d0 1;poke 0xc930 1;poke 0xc8ad 8;poke 0xc990 [expr {[peek 0xc990]|16}]
  word 0xc840 300;poke 0xc801 96
  keymatrixdown 8 16
 }
 incr ::n
 poke 0xc856 8;poke 0xc857 40
 puts $::log "$::n [expr {[peek 0xc840]+256*[peek 0xc841]}] [peek 0xc971] [expr {[peek 0xc972]+256*[peek 0xc973]}]"
 if {$::n==400} {poke 0xc971 5}
 if {$::n>=520} {close $::log;exit;return}
 debug cont
}
debug set_bp $::env(MISSION_LOOP) {} sample
after time 60 {exit 1}
