set throttle off
proc displayed_time {} {
 set reg [debug read "Sunrise GFX9000 regs" 18]
 set page [expr {0xc100+256*($reg&1)}]
 return [expr {10*[peek [expr {$page+0xdf}]]+[peek [expr {$page+0xde}]]}]
}
after time 12 {set ::start [displayed_time]}
after time 12.4 {set ::middle [displayed_time]}
after time 13.2 {
 set f [open $::env(CLOCK_OUT) w]
 puts $f "$::start $::middle [displayed_time]"
 close $f
 exit
}
