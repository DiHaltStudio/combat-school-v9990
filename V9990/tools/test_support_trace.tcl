set throttle off
set ::out [open $::env(SUPPORT_TRACE) w]
proc tick_support {} {
 set t [machine_info time]
 if {$t>=12 && $t<15} {
  set reg [debug read "Sunrise GFX9000 regs" 18]
  set base [expr {0xc100+256*($reg&1)}]
  puts $::out "[format %.4f $t] [peek [expr {$base+6}]] [peek [expr {$base+12}]] [peek [expr {$base+5}]] [peek [expr {$base+3}]] [peek [expr {$base+0x82}]] [peek [expr {$base+0x87}]] [peek [expr {$base+0x30}]] [expr {[peek [expr {$base+0x32}]]+256*[peek [expr {$base+0x33}]]}] [peek [expr {$base+0x8e}]] [peek [expr {$base+0x34}]] [peek [expr {$base+0x36}]] [expr {[peek [expr {$base+0x83}]]+256*[peek [expr {$base+0x84}]]}] [peek [expr {$base+0x85}]]"
 }
 if {$t>=15} {close $::out; exit}
 after frame tick_support
}
after frame tick_support
