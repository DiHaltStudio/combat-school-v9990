set throttle off
set ::seen_bonus 0
set ::seen_map 0
set ::hits $::env(SHOOT_HITS)
set ::out $::env(STEP3_INTEGRATION_OUT)
file mkdir $::out
after time 12 {
    poke 0xc0df 8
    poke 0xc0de 0
    poke 0xc0d5 1
    poke 0xc095 0
}
proc wait_range {} {
    if {[peek 0xc418]!=4} {
        if {[machine_info time]>38} {exit 1}
        after frame wait_range
        return
    }
    poke 0xc414 160
    poke 0xc415 15
    poke 0xc434 $::hits
    poke 0xc435 1
    set previous [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc0dd]-2)&65535}]
    poke 0xc436 [expr {$previous&255}]
    poke 0xc437 [expr {$previous>>8}]
    after frame watch_transition
}
proc watch_transition {} {
    set stage [peek 0xc418]
    if {$stage==5} {set ::seen_bonus 1}
    if {$stage==6} {set ::seen_map 1}
    if {$stage==7} {
        after time 1 verify_step3
        return
    }
    if {[machine_info time]>60} {exit 1}
    after frame watch_transition
}
proc verify_step3 {} {
    set ::start [expr {[peek 0xc700]+256*[peek 0xc701]}]
    set ::seconds [peek 0xc731]
    set ::bonus [peek 0xc43f]
    set ::score [expr {[peek 0xc75c]+256*[peek 0xc75d]}]
    set ::videosource GFX9000
    screenshot -raw "$::out/screen.png"
    poke 0xc710 12
    after time 1 {
        set ::pos [expr {[peek 0xc700]+256*[peek 0xc701]}]
        poke 0xc700 248
        poke 0xc701 1
        poke 0xc714 80
        poke 0xc710 0
        poke 0xc712 0
        poke 0xc713 240
        poke 0xc756 0
        keymatrixdown 8 16
        after time 0.4 {
            keymatrixup 8 16
            set f [open "$::out/result.txt" w]
            puts $f "$::seen_bonus $::seen_map [peek 0xc418] $::bonus $::seconds $::score $::start $::pos [peek 0xc756] [peek 0xc712]"
            close $f
            exit
        }
    }
}
after time 12.1 wait_range
after time 75 {exit 1}
