set throttle off
set ::frame_count 0
set ::out [open $::env(ANIM_LOG) w]
proc observe {} {
 set t [machine_info time]
 if {$t >= 12.0 && $t < 13.5} {
  puts $::out "[format %.4f $t] [peek 0xc000] [peek 0xc001] [peek 0xc008] [peek 0xc030]"
 }
 if {$t >= 13.5} {close $::out; exit}
 after frame observe
}
after frame observe
