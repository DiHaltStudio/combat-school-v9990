set throttle off
set ::cadence_values {}
proc cadence_sample {} {
 lappend ::cadence_values [peek 0xc096]
 if {[llength $::cadence_values] == 6} {
  set f [open $::env(CADENCE_OUT) w]
  puts $f $::cadence_values
  close $f
  exit
 }
 after time 1 cadence_sample
}
after time 12 cadence_sample
