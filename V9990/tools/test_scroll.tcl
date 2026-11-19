proc pulse_scroll {n} {
 if {$n == 0} return
 keymatrixdown 8 1
 after time 0.04 "keymatrixup 8 1; after time 0.06 {pulse_scroll [expr {$n-1}]}"
}
after time 12 { pulse_scroll [expr {[info exists ::env(SCROLL_PULSES)] ? $::env(SCROLL_PULSES) : 70}] }
