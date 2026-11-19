# Qualified ending of Step 4: blinking label while playing, then at time up
# the shooter stands up and raises his arm, and the centred labels appear.
set throttle off
set ::out $::env(STEP4_GOAL_OUT)
file mkdir $::out
proc shot {name} {
    set ::videosource GFX9000
    screenshot -raw "$::out/$name.png"
}
after time 10 {
    poke 0xc809 52
    poke 0xc806 1
    poke 0xc883 0
}
after time 10.25 { shot playing-a }
after time 10.35 { shot playing-b }
after time 10.5 {
    poke 0xc806 0
    poke 0xc883 1
    set previous [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc882]-2)&65535}]
    poke 0xc81a [expr {$previous&255}]
    poke 0xc81b [expr {$previous>>8}]
}
after time 10.8 { shot end-idle }
after time 11.3 { shot end-stand }
after time 11.8 { shot end-raised }
after time 12.6 {
    shot end-labels
    set f [open "$::out/state.txt" w]
    puts $f "[peek 0xc80c] [peek 0xc806] [peek 0xc883]"
    close $f
    exit
}
