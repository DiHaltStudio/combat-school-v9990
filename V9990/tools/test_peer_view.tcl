set throttle off
after time 12 {
    set scroll $::env(PEER_SCROLL)
    poke 0xc000 100
    poke 0xc006 144
    poke 0xc00c 1
    poke 0xc092 100
    poke 0xc090 [expr {$scroll&255}]
    poke 0xc091 [expr {$scroll>>8}]
    poke 0xc095 1
}
