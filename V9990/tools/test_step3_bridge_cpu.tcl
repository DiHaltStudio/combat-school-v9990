set throttle off
set ::results {}
proc setup_cpu {p x} {
    poke 0xc702 [expr {$p&255}]
    poke 0xc703 [expr {$p>>8}]
    poke 0xc715 $x
    poke 0xc757 0
    poke 0xc713 0
    poke 0xc73b 0
    poke 0xc730 0
    poke 0xc716 0
    poke 0xc710 0
}
proc entered {} {lappend ::results [peek 0xc757] [peek 0xc713]}
proc start_exit {p} {
    poke 0xc702 [expr {$p&255}]
    poke 0xc703 [expr {$p>>8}]
    poke 0xc715 88
    poke 0xc757 1
    poke 0xc713 0
}
proc exited {} {lappend ::results [peek 0xc757] [peek 0xc713]}
after time 10 {set ::videosource GFX9000; setup_cpu 496 88}
after time 10.12 {entered; screenshot -raw "[file dirname $::env(STEP3_BRIDGE_CPU_RESULT)]/bridge-test/cpu-wade.png";start_exit 544}
after time 10.4 {exited;setup_cpu 960 88}
after time 10.52 {entered;start_exit 1008}
after time 10.8 {exited;setup_cpu 1728 88}
after time 10.92 {entered;start_exit 1784}
after time 11.2 {
    exited
    set f [open $::env(STEP3_BRIDGE_CPU_RESULT) w]
    puts $f $::results
    close $f
    exit
}
