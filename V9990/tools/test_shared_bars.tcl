set throttle off
after time 12 {
    poke 0xc000 100
    poke 0xc092 100
    poke 0xc006 [expr {2100&255}]
    poke 0xc00c [expr {2100>>8}]
    poke 0xc090 [expr {2050&255}]
    poke 0xc091 [expr {2050>>8}]
    poke 0xc00a 1
    poke 0xc005 24
    poke 0xc0c4 1
    poke 0xc093 136
    poke 0xc0fc 0
    poke 0xc0fd 0
}
