set throttle off
set ::marked 0
proc observe {} {
 set tick [expr {[peek 0xc8e4]+256*[peek 0xc8e5]}]
 if {$tick>=295 && !$::marked && [peek 0xc8f3]==0} {
  poke [expr {0xc980+14}] 1
  set ::marked 1
 }
 if {$tick>=320 && [peek 0xc8f3]==0} {
  set dead 0; set other 0
  for {set i 0} {$i<16} {incr i} {
   if {[peek [expr {0xc900+$i}]]} {
    set id [peek [expr {0xc950+$i}]]
    if {$id==14} {set dead 1}
    if {$id==15} {set other 1}
   }
  }
  set f [open $::env(STEP4_FRAGMENTS_RESULT) w]
  puts $f "$dead $other [peek [expr {0xc980+14}]]";close $f;exit
 }
 if {[machine_info time]>25} {exit 1}
 after frame observe
}
after time 6 observe
