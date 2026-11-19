set throttle off
set ::n -1
file mkdir $::env(MISSION_TEST_OUT)
proc word {addr value} {poke $addr [expr {$value&255}];poke [expr {$addr+1}] [expr {$value>>8}]}
proc centre {} {expr {[peek 0xc840]+256*[peek 0xc841]+[peek 0xc801]+32}}
proc sample {} {
 for {set row 0} {$row<11} {incr row} {keymatrixup $row 255}
 if {$::n<0} {
  if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {debug cont;return}
  set ::n 0
  foreach a {0xc851 0xc871 0xc891 0xc8c1 0xc8e9 0xc911 0xc921 0xc941 0xc951 0xc961 0xc971} {poke $a 5}
  foreach a {0xc8a2 0xca02 0xc8d4 0xc823 0xc803 0xc804 0xc806 0xc80a 0xc981 0xc8de 0xc8df} {poke $a 0}
  poke 0xc8da 1;poke 0xc8d0 1;poke 0xc930 1;poke 0xc8e0 1;poke 0xc900 1;poke 0xc990 49
  poke 0xc97f 8;word 0xc972 0
  word 0xc840 440;poke 0xc801 96;poke 0xc8dd 1
 } else {incr ::n}
 if {$::n<50} {
  keymatrixdown 8 16
  if {[centre]<550} {error "passed the doorway while hanging"}
  if {$::n==25} {set ::phase [peek 0xc8df]}
  if {$::n==49} {
   if {[centre]!=550 || [peek 0xc8dd]!=1} {error "did not stop at left pipe end"}
   if {[peek 0xc8df]!=$::phase} {error "animating against the blocked endpoint"}
  }
 }
 if {$::n==50} {keymatrixdown 4 4}
 if {$::n==51 && [peek 0xc8dd]!=0} {error "M cannot release at pipe end"}
 if {$::n==80} {
  word 0xc840 978;poke 0xc801 96;poke 0xc8dd 1;poke 0xc804 0;poke 0xc823 0
 }
 if {$::n>=80 && $::n<130} {
  keymatrixdown 8 128
  if {[centre]>1124} {error "passed the right pipe end"}
 }
 if {$::n==130} {
  if {[centre]!=1124 || [peek 0xc8dd]!=1} {error "did not stop at right pipe end"}
  keymatrixdown 4 4
 }
 if {$::n==131 && [peek 0xc8dd]!=0} {error "cannot release at right end"}
 if {$::n==160} {
  word 0xc840 300;poke 0xc801 96;poke 0xc804 18;poke 0xc8dd 0
 }
 if {$::n>160 && [peek 0xc8dd]!=0} {error "grabbed invisible pipe in brick room"}
 if {$::n==190} {
  set f [open "$::env(MISSION_TEST_OUT)/result.txt" w];puts $f "OK: both pipe endpoints, blocked animation, M release and no pipe in next room";close $f
  exit;return
 }
 debug cont
}
proc safe_sample {} {if {[catch {sample} message]} {puts stderr "FAIL: $message at $::n, centre=[centre]";exit 1}}
debug set_bp $::env(MISSION_LOOP) {} safe_sample
after time 30 {exit 1}
