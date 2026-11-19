set throttle off
set f [open $::env(INSTRUCTOR_OUT) w]
proc sample_instructor {} {
    set t [machine_info time]
    set reg [debug read "Sunrise GFX9000 regs" 18]
    set p [expr {0xc100+256*($reg&1)}]
    puts $::f "[format %.3f $t] [peek [expr {$p+0xba}]] [peek [expr {$p+0xd0}]] [peek [expr {$p+0x00}]] [peek [expr {$p+0x92}]] [peek [expr {$p+0xbb}]] [peek [expr {$p+0xbe}]] [peek [expr {$p+0xd9}]]"
    if {$t >= 16} {close $::f; exit}
    after frame sample_instructor
}
after time 7 sample_instructor
after time 12 {
    poke 0xc000 100
    poke 0xc006 184
    poke 0xc00c 9
    poke 0xc008 48
    poke 0xc00b 60
}
