set throttle off
set ::out $::env(STEP3_RESTART_OUT)
file mkdir $::out
after time 10 {
    poke 0xc731 8
    poke 0xc701 13
    poke 0xc72f 0
    poke 0xc735 0
    set ::videosource GFX9000
}
after time 10.5 {
    set ::remaining [peek 0xc731]
    set ::bonus [peek 0xc736]
    set ::points [expr {[peek 0xc739]+256*[peek 0xc73a]}]
    screenshot -raw "$::out/bonus.png"
    keymatrixdown 8 1
}
after time 11.0 {keymatrixup 8 1}
after time 13 {
    set f [open "$::out/result.txt" w]
    puts $f "$::bonus $::points $::remaining [peek 0xc72e] [peek 0xc72f] [peek 0xc735] [peek 0xc731] [peek 0xc701]"
    close $f
    exit
}
