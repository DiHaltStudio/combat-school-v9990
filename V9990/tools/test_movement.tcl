proc pulse_run {n} {
 if {$n == 0} return
 keymatrixdown 8 0x01
 after time 0.06 "keymatrixup 8 0x01; after time 0.06 {pulse_run [expr {$n-1}]}"
}
after time 12 { pulse_run 8 }
