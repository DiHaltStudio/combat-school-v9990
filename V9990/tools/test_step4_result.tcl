set throttle off
after time 10 {
    poke 0xc809 $::env(STEP4_HITS)
    poke 0xc806 0
    poke 0xc883 1
    set previous [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc882]-2)&65535}]
    poke 0xc81a [expr {$previous&255}]
    poke 0xc81b [expr {$previous>>8}]
}
after time 10.5 {
    set f [open $::env(STEP4_RESULT) w]
    puts $f "[peek 0xc80c] [peek 0xc806] [peek 0xc809]"
    close $f
    exit
}
