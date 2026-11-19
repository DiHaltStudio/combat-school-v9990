# Kick reach against the first assailant (c850): held at MISSION_KICK_DIST
# pixels to the right of the player, facing it, while the player kicks once.
# result.txt: distance and 1 if the assailant entered the hit state (c851=2).
set throttle off
catch {set vsync off}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::dist $::env(MISSION_KICK_DIST)
set ::n -1
proc place {} {
 set p [expr {[peek 0xc840]+256*[peek 0xc841]+[peek 0xc801]+$::dist}]
 poke 0xc852 [expr {$p&255}];poke 0xc853 [expr {$p>>8}]
}
proc sample {} {
 if {$::n<0} {
  if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {debug cont;return}
  set ::n 0
  # Only the first assailant, approaching; the player faces right.
  poke 0xc871 0;poke 0xc891 0;poke 0xc8d0 1;poke 0xc8c1 0;poke 0xc930 1;poke 0xc911 0
  poke 0xc851 1;poke 0xc854 0;poke 0xc858 0;poke 0xc809 0
 }
 incr ::n
 poke 0xc856 8;poke 0xc857 40
 if {[peek 0xc851]==1} {place}
 if {$::n==5} {keymatrixdown 8 1}
 if {$::n==8} {keymatrixup 8 1}
 if {[peek 0xc851]==2 || $::n==60} {
  set f [open "$::out/result.txt" w];puts $f "$::dist [expr {[peek 0xc851]==2}]";close $f
  exit;return
 }
 debug cont
}
debug set_bp $::env(MISSION_LOOP) {} sample
after time 60 {exit 1}
