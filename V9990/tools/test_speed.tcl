set throttle off
after time 12 {
 set ::cpu_start [expr {[peek 0xc090]+256*[peek 0xc091]}]
 set ::time_start [peek 0xc0d0]
}
after time 14 {
 set f [open $::env(SPEED_OUT) w]
 puts $f "$::cpu_start [expr {[peek 0xc090]+256*[peek 0xc091]}] $::time_start [peek 0xc0d0]"
 close $f
 exit
}
