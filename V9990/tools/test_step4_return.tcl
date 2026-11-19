set throttle off
set ::marked 0
proc observe {} {
 set tick [expr {[peek 0xc8e4]+256*[peek 0xc8e5]}]
 if {$tick >= 50 && !$::marked && [peek 0xc8f3] == 0} {
  poke 0xc980 1
  set ::marked 1
 }
 if {$tick >= 90 && [peek 0xc8f3] == 0} {
  set found0 0; set found1 0; set view1 -1
  for {set i 0} {$i<16} {incr i} {
   if {[peek [expr {0xc900+$i}]]} {
    set id [peek [expr {0xc950+$i}]]
    if {$id==0} {set found0 1}
    if {$id==1} {set found1 1;set view1 [expr {[peek [expr {0xc930+$i}]] & 3}]}
   }
  }
  set f [open $::env(STEP4_RETURN_RESULT) w]
  puts $f "$found0 $found1 $view1 [peek 0xc980]"
  close $f;exit
 }
 if {[machine_info time]>15} {exit 1}
 after frame observe
}
after time 6 observe
