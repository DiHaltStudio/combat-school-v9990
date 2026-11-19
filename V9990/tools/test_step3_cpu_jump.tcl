set throttle off
set ::saw_jump 0
proc watch_cpu_jump {} {
    if {[peek 0xc73b] > 0} {set ::saw_jump 1}
    after frame watch_cpu_jump
}
after time 10 {
    poke 0xc702 208
    poke 0xc703 2
    poke 0xc713 0
    poke 0xc73b 0
    poke 0xc714 8
    poke 0xc715 48
    poke 0xc716 0
    watch_cpu_jump
}
after time 12 {
    set f [open $::env(STEP3_CPU_JUMP_RESULT) w]
    puts $f "$::saw_jump [expr {[peek 0xc702] + 256*[peek 0xc703]}] [peek 0xc713]"
    close $f
    exit
}
