set run_test_mode $::env(RUN_TEST)
proc pulse {remaining interval} {
 if {$remaining <= 0} return
 keymatrixdown 8 0x01
 after time 0.04 "keymatrixup 8 0x01; after time [expr {$interval-0.04}] {pulse [expr {$remaining-1}] $interval}"
}
if {$run_test_mode eq "fast"} { after time 12 { pulse 12 0.10 } }
if {$run_test_mode eq "slow"} { after time 12 { pulse 4 0.30 } }
if {$run_test_mode eq "held"} { after time 12 {keymatrixdown 8 0x01}; after time 13.2 {keymatrixup 8 0x01} }
