set throttle off
set ::marked 0
set ::counts {}
set ::next 680
set ::ids {28 29 30 31 32 33 34}
proc observe {} {
 set tick [expr {[peek 0xc8e4]+256*[peek 0xc8e5]}]
 if {$tick>=600 && !$::marked && [peek 0xc8f3]==0} {
  foreach id $::ids {
   if {$::env(STEP4_SURVIVOR) ne "$id"} {poke [expr {0xc980+$id}] 1}
  }
  set ::marked 1
 }
 if {$tick >= $::next && [peek 0xc8f3]==0} {
  set count 0;set survivor 0;set others 0
  for {set i 0} {$i<16} {incr i} {
   if {[peek [expr {0xc900+$i}]]} {
    set id [peek [expr {0xc950+$i}]]
    if {$id in $::ids} {
     incr count
     if {$id == 31} {set survivor 1}
    } else {incr others}
   }
  }
  lappend ::counts $count $survivor $others
  incr ::next 40
 }
 if {$::next>720} {
  set f [open $::env(STEP4_CONVOY_RESULT) w]; puts $f $::counts;close $f;exit
 }
 if {[machine_info time]>40} {exit 1}
 after frame observe
}
after time 6 observe
