set throttle off
set ::out [open $::env(ANIM_LOG) w]
proc trace_hang {} {
 set t [machine_info time]
 if {$t>=12 && $t<15} {
  puts $::out "[peek 0xc00a] [peek 0xc030] [peek 0xc032] [peek 0xc033]"
 }
 if {$t>=15} {close $::out; exit}
 after frame trace_hang
}
after frame trace_hang
