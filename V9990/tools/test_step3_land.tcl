set throttle off
set ::out $::env(STEP3_LAND_OUT)
file mkdir $::out
after time 10 {
    set ::videosource GFX9000
    poke 0xc710 0
    poke 0xc730 1
    poke 0xc700 120
    poke 0xc701 0
    poke 0xc702 120
    poke 0xc703 0
}
after time 10.4 {
    screenshot -raw "$::out/early.png"
    poke 0xc700 240
    poke 0xc702 240
}
after time 10.8 {
    screenshot -raw "$::out/bridge.png"
    poke 0xc700 120
    poke 0xc701 1
    poke 0xc702 120
    poke 0xc703 1
}
after time 11.2 {
    screenshot -raw "$::out/later.png"
    exit
}
