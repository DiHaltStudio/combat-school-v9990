proc pulse {n} {
 if {$n<=0} return
 keymatrixdown 8 1
 after time 0.04 "keymatrixup 8 1; after time 0.06 {pulse [expr {$n-1}]}"
}
after time 12 {
 poke 0xc000 100
 poke 0xc006 190
 poke 0xc00c 0
 poke 0xc008 24
 poke 0xc00b 60
}
