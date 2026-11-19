set throttle off
set ::trace_file [open $::env(WALL_TRACE) w]
proc trace_wall {} {
 set t [machine_info time]
 if {$t>=12 && $t<15.5} {
  puts $::trace_file "[format %.5f $t] [peek 0xc100] [peek 0xc106] [peek 0xc10c] [peek 0xc105] [peek 0xc182] [peek 0xc186]"
 }
 if {$t>=15.5} {close $::trace_file; exit}
 after frame trace_wall
}
after frame trace_wall
