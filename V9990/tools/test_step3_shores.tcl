set throttle off
set ::out $::env(STEP3_SHORES_OUT)
file mkdir $::out
proc position {p} {
    poke 0xc700 [expr {$p&255}]
    poke 0xc701 [expr {$p>>8}]
    poke 0xc702 [expr {$p&255}]
    poke 0xc703 [expr {$p>>8}]
    poke 0xc710 0
    poke 0xc730 1
    poke 0xc714 8
    poke 0xc715 96
}
after time 10 {set ::videosource GFX9000; position 1984}
after time 10.3 {screenshot -raw "$::out/entry-before.png"; position 2064}
after time 10.6 {screenshot -raw "$::out/entry-after.png"; position 3032}
after time 10.9 {screenshot -raw "$::out/exit-before.png"; position 3096}
after time 11.2 {screenshot -raw "$::out/exit-after.png"; position 3292}
after time 11.5 {screenshot -raw "$::out/finish-approach.png"; exit}
