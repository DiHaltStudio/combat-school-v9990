set throttle off
set ::wave_rows {}
set ::shot 0
after time 12 {
    poke 0xc0df 8
    poke 0xc0de 0
    poke 0xc0d5 1
}
proc wait_shoot_44 {} {
    if {[peek 0xc418] == 4} {after time 0.5 shoot_next} else {after frame wait_shoot_44}
}
proc shoot_next {} {
    if {$::shot > 44} {return}
    if {$::shot == 44} {
        set ::shot 45
        set result_file [open $::env(SHOOT_RESULT) w]
        puts $result_file "[peek 0xc434] [peek 0xc432] [peek 0xc435] [peek 0xc43a]"
        close $result_file
        set waves_file [open $::env(SHOOT_WAVES) w]
        puts $waves_file [join $::wave_rows "\n"]
        close $waves_file
        exit
    }
    set mask [peek 0xc432]
    lappend ::wave_rows "$mask [peek 0xc44a] [peek 0xc44b] [peek 0xc44c] [peek 0xc44d] [peek 0xc43b]"
    set slot 0
    while {(($mask >> $slot) & 1) == 0} {incr slot}
    poke 0xc430 [peek [expr {0xc44a+$slot}]]
    poke 0xc431 [peek 0xc43b]
    keymatrixdown 8 1
    after time 0.10 {
        keymatrixup 8 1
        incr ::shot
        after time 0.10 shoot_next
    }
}
after time 12.1 wait_shoot_44
after time 45 {exit 1}
