set throttle off
set ::records {}
set ::next 120
set ::out $::env(STEP4_TIMELINE_RESULT)
proc observe {} {
    set tick [expr {[peek 0xc8e4]+256*[peek 0xc8e5]}]
    if {$::env(STEP4_CLEAR) eq "1"} {
        for {set i 0} {$i<16} {incr i} {poke [expr {0xc900+$i}] 0}
    }
    if {$tick >= $::next && [peek 0xc8f3] == 0} {
        set cursor [expr {[peek 0xc8e6]+256*[peek 0xc8e7]}]
        set active 0
        for {set i 0} {$i<16} {incr i} {incr active [peek [expr {0xc900+$i}]]}
        lappend ::records $tick $cursor [peek 0xc8e8] $active
        if {$::next == 120 && $::env(STEP4_CLEAR) eq "0"} {set ::videosource GFX9000;screenshot -raw "$::env(STEP4_TIMELINE_SCREEN)"}
        incr ::next 120
    }
    if {$::next>1080} {
        set f [open $::out w];puts $f $::records;close $f;exit
    }
    if {[machine_info time]>60} {exit 1}
    after frame observe
}
after time 7 observe
after time 65 {exit 1}
