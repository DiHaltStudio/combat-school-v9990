set throttle off
set ::last 0
set ::result {}
proc observe {} {
 set tick [expr {[peek 0xc8e4]+256*[peek 0xc8e5]}]
 if {$tick >= 1150 && !$::last && [peek 0xc8f3]==0} {
  set ::last 1
  set ::values {}
  for {set i 0} {$i<16} {incr i} {if {[peek [expr {0xc900+$i}]]} {lappend ::values [peek [expr {0xc950+$i}]] [peek [expr {0xc910+$i}]] [peek [expr {0xc920+$i}]]}}
  set ::state [peek 0xc80c]
 }
 if {$tick >= 1160 && $::last && [peek 0xc8f3]==0} {
  set values {}
  for {set i 0} {$i<16} {incr i} {if {[peek [expr {0xc900+$i}]]} {lappend values [peek [expr {0xc950+$i}]] [peek [expr {0xc910+$i}]] [peek [expr {0xc920+$i}]]}}
  set f [open $::env(STEP4_TAIL_RESULT) w];puts $f "$::state [peek 0xc80c] [expr {$::values ne $values}] [llength $::values] [llength $values]";close $f;exit
 }
 if {[machine_info time]>55} {exit 1}
 after frame observe
}
after time 6 observe
