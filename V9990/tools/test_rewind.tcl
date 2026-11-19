set throttle off
after time 2 {
    reverse stop
    source tools/run_demo.tcl
}
after time 10 {
    set f [open $::env(REWIND_RESULT) w]
    set status [dict get [reverse status] status]
    set back_binding [bind PAGEUP]
    set forward_binding [bind PAGEDOWN]
    set keypad_back_binding [bind "keyb {Keypad 9}"]
    set keypad_forward_binding [bind "keyb {Keypad 3}"]
    set pause on
    set before [dict get [reverse status] current]
    go_back_one_step
    set back [dict get [reverse status] current]
    go_forward_one_step
    set forward [dict get [reverse status] current]
    puts $f "$status $before $back $forward"
    puts $f "$back_binding$forward_binding$keypad_back_binding$keypad_forward_binding"
    close $f
    exit
}
after time 15 {exit 1}
