set throttle off
set ::out $::env(STEP4_FINAL_LOOP_RESULT)
set ::initial -1
set ::marked 0
set ::next 1150
set ::values {}
proc observe {} {
 set tick [expr {[peek 0xc8e4]+256*[peek 0xc8e5]}]
 if {$::initial<0 && $tick>0} {set ::initial [peek 0xc806]}
 if {$tick >= 1145 && !$::marked && [peek 0xc8f3]==0} {
  poke [expr {0xc980+64}] 1
  set ::marked 1
 }
 if {$tick >= $::next && [peek 0xc8f3]==0} {
  set found 0;set count 0;set signature {}
  for {set i 0} {$i<16} {incr i} {
   if {[peek [expr {0xc900+$i}]]} {
    set id [peek [expr {0xc950+$i}]]
    if {$id==64} {set found 1}
    incr count
    lappend signature $id [peek [expr {0xc910+$i}]] [peek [expr {0xc920+$i}]]
   }
  }
  lappend ::values [peek 0xc80c] $found $count
  if {$::next==1150} {set ::first $signature}
  if {$::next==1165} {set ::moved [expr {$::first ne $signature}]}
  incr ::next 15
 }
 if {$::next>1165} {
  set f [open $::out w];puts $f "$::initial $::values $::moved";close $f;exit
 }
 if {[machine_info time]>58} {exit 1}
 after frame observe
}
after time 6 observe
