proc pulse {n} {
 if {$n<=0} return
 keymatrixdown 8 1
 after time 0.04 "keymatrixup 8 1; after time 0.06 {pulse [expr {$n-1}]}"
}
after time 12 {
 poke 0xc000 100
 poke 0xc006 126
 poke 0xc00c 7
 keymatrixdown 4 4
 pulse 25
}
after time 12.12 { keymatrixup 4 4 }
