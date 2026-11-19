set throttle off
set ::out $::env(STEP3_BRIDGE_OUT)
file mkdir $::out
set ::result {}
proc setup {p x} {
    poke 0xc700 [expr {$p&255}]
    poke 0xc701 [expr {$p>>8}]
    poke 0xc714 $x
    poke 0xc710 0
    poke 0xc70f 0
    poke 0xc712 0
    poke 0xc713 240
    poke 0xc730 1
    poke 0xc744 0
    poke 0xc756 0
}
proc begin {p x} {setup $p $x; keymatrixdown 8 128}
proc entered {n} {
    keymatrixup 8 128
    lappend ::result [peek 0xc756] [peek 0xc712] [peek 0xc714]
    screenshot -raw "$::out/wade-$n.png"
    keymatrixdown 8 16
}
proc blocked {} {
    keymatrixup 8 16
    lappend ::result [peek 0xc756] [peek 0xc714]
    keymatrixdown 4 4
}
proc attempt_jump {} {keymatrixup 4 4; lappend ::result [peek 0xc70f]}
proc exit_water {p} {
    poke 0xc700 [expr {$p&255}]
    poke 0xc701 [expr {$p>>8}]
    poke 0xc714 72
    poke 0xc756 1
    poke 0xc710 12
    poke 0xc712 0
}
proc exited {} {lappend ::result [peek 0xc756] [peek 0xc712]}
after time 10 {set ::videosource GFX9000; begin 504 80}
after time 10.4 {entered 1}
after time 10.9 {blocked}
after time 11.1 {attempt_jump;exit_water 544}
after time 11.5 {exited;begin 960 88}
after time 11.9 {entered 2}
after time 12.4 {blocked}
after time 12.6 {attempt_jump;exit_water 1008}
after time 13.0 {exited;begin 1728 64}
after time 13.4 {entered 3}
after time 13.9 {blocked}
after time 14.1 {attempt_jump;exit_water 1784}
after time 14.5 {
    exited
    set f [open "$::out/result.txt" w]
    puts $f $::result
    close $f
    exit
}
