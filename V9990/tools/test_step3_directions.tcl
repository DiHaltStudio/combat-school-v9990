set throttle off
set ::out $::env(STEP3_DIRECTION_OUT)
file mkdir $::out
proc snapshot {name} {screenshot -raw "$::out/$name.png"}
after time 10 {
    set ::videosource GFX9000
    poke 0xc700 184
    poke 0xc701 1
    poke 0xc714 40
    poke 0xc710 0
    poke 0xc712 0
    poke 0xc713 240
    poke 0xc716 0
    keymatrixdown 8 128
}
after time 10.4 {
    set ::right_x [peek 0xc714]
    set ::right_power [peek 0xc710]
    set ::right_dir [peek 0xc746]
    set ::right_progress [expr {[peek 0xc700]+256*[peek 0xc701]}]
    snapshot right
    keymatrixup 8 128
    keymatrixdown 8 64
}
after time 10.8 {
    set ::down_progress [expr {[peek 0xc700]+256*[peek 0xc701]}]
    set ::down_power [peek 0xc710]
    set ::down_dir [peek 0xc746]
    snapshot down
    keymatrixdown 4 4
}
after time 10.9 {
    set ::jump [peek 0xc70f]
    set ::jump_power [peek 0xc710]
    keymatrixup 4 4
}
after time 11.0 {keymatrixdown 8 1}
after time 11.1 {keymatrixup 8 1}
after time 11.2 {keymatrixdown 8 1}
after time 11.3 {
    set ::boost [peek 0xc710]
    keymatrixup 8 1
    keymatrixup 8 64
    keymatrixdown 8 16
}
after time 11.6 {
    set f [open "$::out/result.txt" w]
    puts $f "$::right_x $::right_power $::right_dir $::right_progress $::down_progress $::down_power $::down_dir $::boost $::jump $::jump_power [peek 0xc714] [peek 0xc746]"
    close $f
    snapshot left
    exit
}
