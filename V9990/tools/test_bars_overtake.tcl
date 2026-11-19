set throttle off
set ::overtake_log [open $::env(OVERTAKE_OUT) w]
after time 12 {
    poke 0xc000 100
    poke 0xc092 100
    poke 0xc006 [expr {2080&255}]
    poke 0xc00c [expr {2080>>8}]
    poke 0xc090 [expr {2088&255}]
    poke 0xc091 [expr {2088>>8}]
    poke 0xc00a 1
    poke 0xc005 24
    poke 0xc0c4 1
    poke 0xc093 136
    poke 0xc0fc 0
    poke 0xc0fd 0
    poke 0xc0fe 0
    poke 0xc0ff 0
    if {$::env(OVERTAKE_CASE) eq "cpu_passes"} {
        poke 0xc006 [expr {2100&255}]
        poke 0xc00c [expr {2100>>8}]
    } elseif {$::env(OVERTAKE_CASE) eq "different_height"} {
        poke 0xc00a 0
        poke 0xc005 55
    }
}
after time 12.15 {
    if {$::env(OVERTAKE_CASE) eq "player_passes"} {
        set pos [expr {[peek 0xc090]+256*[peek 0xc091]+8}]
        poke 0xc006 [expr {$pos&255}]
        poke 0xc00c [expr {$pos>>8}]
    }
}
proc sample_overtake {} {
    set t [machine_info time]
    if {$t>=12 && $t<14} {
        puts $::overtake_log "[format %.4f $t] [peek 0xc00a] [peek 0xc005] [peek 0xc086] [peek 0xc0c4] [peek 0xc093] [peek 0xc0fe] [peek 0xc0fd] [peek 0xc0fc] [expr {[peek 0xc006]+256*[peek 0xc00c]+[peek 0xc000]}] [expr {[peek 0xc090]+256*[peek 0xc091]+[peek 0xc092]}] [peek 0xc0d9] [peek 0xc0ff] [peek 0xc030] [expr {[peek 0xc032]+256*[peek 0xc033]}] [peek 0xc0a0] [expr {[peek 0xc0a2]+256*[peek 0xc0a3]}]"
    }
    if {$t>=14} {close $::overtake_log; exit}
    after frame sample_overtake
}
after time 12 sample_overtake
