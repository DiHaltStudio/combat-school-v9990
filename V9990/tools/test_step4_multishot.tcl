set throttle off
set ::out $::env(STEP4_MULTISHOT_OUT)
file mkdir $::out
proc clear_targets {} {
 poke 0xc8e4 0x00;poke 0xc8e5 0x06
 for {set i 0} {$i<16} {incr i} {poke [expr {0xc900+$i}] 0}
}
after time 10 {set ::videosource GFX9000;clear_targets;keymatrixdown 8 1}
after time 10.3 {
 set ::count [peek 0xc803];set ::positions {}
 if {[peek 0xc803]} {lappend ::positions [peek 0xc802]}
 for {set i 0} {$i<7} {incr i} {
  set slot [expr {0xca00+3*$i}]
  if {[peek [expr {$slot+2}]]} {incr ::count;lappend ::positions [peek [expr {$slot+1}]]}
 }
 screenshot -raw "$::out/shots.png"
 keymatrixup 8 1
}
after time 10.8 {
 clear_targets
 poke 0xc803 0
 for {set i 0} {$i<7} {incr i} {poke [expr {0xca02+3*$i}] 0}
 poke 0xc900 1;poke 0xc910 80;poke 0xc920 40;poke 0xc930 1;poke 0xc950 110
 poke 0xc809 0;poke 0xc9ee 0
 poke 0xca00 84;poke 0xca01 50;poke 0xca02 1
}
after time 11.0 {
 set f [open "$::out/result.txt" w]
 puts $f "$::count [llength [lsort -unique $::positions]] [peek 0xc809] [peek 0xc9ee] [peek 0xca02]"
 close $f;exit
}
