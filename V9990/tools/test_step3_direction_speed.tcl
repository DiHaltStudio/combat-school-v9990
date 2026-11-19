set throttle off
proc reset_runner {power} {
    poke 0xc700 184
    poke 0xc701 1
    poke 0xc714 24
    poke 0xc710 $power
    poke 0xc712 0
    poke 0xc713 240
    poke 0xc716 0
    poke 0xc744 0
}
after time 10 {reset_runner 0; keymatrixdown 8 128}
after time 10.4 {set ::side_low [expr {[peek 0xc714]-24}]; reset_runner 12}
after time 10.8 {set ::side_high [expr {[peek 0xc714]-24}]; keymatrixup 8 128; reset_runner 0; keymatrixdown 8 64}
after time 11.2 {set ::back_low [expr {440-([peek 0xc700]+256*[peek 0xc701])}]; reset_runner 12}
after time 11.6 {set ::back_high [expr {440-([peek 0xc700]+256*[peek 0xc701])}]; keymatrixup 8 64; reset_runner 12}
after time 12.0 {
    set forward [expr {[peek 0xc700]+256*[peek 0xc701]-440}]
    set f [open $::env(STEP3_SPEED_RESULT) w]
    puts $f "$::side_low $::side_high $::back_low $::back_high $forward"
    close $f
    exit
}
