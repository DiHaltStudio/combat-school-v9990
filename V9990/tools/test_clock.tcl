set throttle off
after time 12 {set ::initial_seconds [peek 0xc0d0]}
after time 17 {
 set final_seconds [peek 0xc0d0]
 set f [open $::env(CLOCK_OUT) w]
 puts $f "$::initial_seconds $final_seconds [peek 0xc0dd]"
 close $f
 exit
}
