after time 12 {
 poke 0xc000 100
 poke 0xc006 [expr {[info exists ::env(IMPACT_SCROLL)] ? $::env(IMPACT_SCROLL) % 256 : 190}]
 poke 0xc00c [expr {[info exists ::env(IMPACT_SCROLL)] ? $::env(IMPACT_SCROLL) / 256 : 0}]
 poke 0xc008 $::env(IMPACT_SPEED)
 poke 0xc00b 60
}
