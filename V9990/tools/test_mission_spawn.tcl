set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::started 0
proc watch_spawn {} {
 if {[peek 0xc856]==8 && [peek 0xc850]>0 && [peek 0xc851]==0} {set ::started 1}
 if {$::started && (([peek 0xc851]==1) != ([peek 0xc871]==1))} {
  puts stderr "The first two assailants did not spawn together"
  exit 1
 }
 if {$::started && [peek 0xc851]==1 && [peek 0xc871]==1} {
  set ::before [expr {[peek 0xc852]+256*[peek 0xc853]}]
  set ::other_before [expr {[peek 0xc872]+256*[peek 0xc873]}]
  after time 0.2 {
   set f [open "$::out/spawn.txt" w]
   puts $f "$::before [expr {[peek 0xc852]+256*[peek 0xc853]}] $::other_before [expr {[peek 0xc872]+256*[peek 0xc873]}] [peek 0xc851] [peek 0xc871] [peek 0xc856]";close $f
   exit
  }
  return
 }
 after frame watch_spawn
}
after time 1 {after frame watch_spawn}
after time 15 {exit 1}
