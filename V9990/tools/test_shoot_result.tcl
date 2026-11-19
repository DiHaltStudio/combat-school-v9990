set throttle off
set ::f [open $::env(SHOOT_RESULT) w]
after time 12 {
    poke 0xc0df 8
    poke 0xc0de 0
    poke 0xc0d5 1
}
proc wait_shoot_result {} {
    if {[peek 0xc418] == 4} {
        poke 0xc434 $::env(SHOOT_HITS)
        poke 0xc435 1
        set previous [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc0dd]-2)&65535}]
        poke 0xc436 [expr {$previous&255}]
        poke 0xc437 [expr {$previous>>8}]
        set wait [expr {$::env(SHOOT_HITS) < 44 ? 4.0 : 0.5}]
        after time $wait {
            puts $::f "[peek 0xc43a] [peek 0xc435] [peek 0xc43f] [expr {[peek 0xc440]+256*[peek 0xc441]}] [peek 0xc418]"
            close $::f
            exit
        }
    } else {
        if {[machine_info time] > 30} {exit 1}
        after frame wait_shoot_result
    }
}
after time 12.1 wait_shoot_result
