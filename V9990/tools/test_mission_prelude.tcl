# Screens before the mission (src/mission_prelude.asm): screenshots while
# "ATTENTION!" is typed and the soldiers salute, and during the mansion;
# prelude.txt logs per display frame: time, screen, frames left, page.
set throttle off
catch {set vsync off}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::log [open "$out/prelude.txt" w]
set ::shots {{attention 450 typing} {attention 100 soldiers} {mansion 300 mansion-a} {mansion 200 mansion-b} {mansion 40 mansion-c}}
proc watch {} {
 set screen [expr {[peek 0xd003]+256*[peek 0xd004]}]
 set left [expr {[peek 0xd001]+256*[peek 0xd002]}]
 puts $::log "[machine_info time] $screen $left [peek 0xd000] [peek 0xc856]"
 if {[llength $::shots]} {
  lassign [lindex $::shots 0] which at name
  set want [expr {$which eq "attention" ? $::att : $::man}]
  if {$screen==$want && $left<=$at && $left>0} {
   set ::videosource GFX9000
   # The first screenshot after selecting the V9990 output can fail: retry.
   if {![catch {screenshot -raw "$::out/$name.png"}]} {
    set f [open "$::out/$name.txt" w];puts $f $left;close $f
    set ::shots [lrange $::shots 1 end]
   }
  }
 }
 if {[peek 0xc856]==8 && $::started} {close $::log;exit;return}
 if {$left>0} {set ::started 1}
 after frame watch
}
set ::started 0
set ::att $::env(PRELUDE_ATTENTION)
set ::man $::env(PRELUDE_MANSION)
after frame watch
after time 60 {exit 1}
