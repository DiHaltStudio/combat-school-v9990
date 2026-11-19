set throttle off
set ::out $::env(STEP4_VIEWS_OUT)
file mkdir $::out
proc setup {view} {
    poke 0xc8e4 0x00; poke 0xc8e5 0x06
    for {set i 0} {$i<16} {incr i} {poke [expr {0xc900+$i}] 0}
    poke 0xc900 1; poke 0xc910 110; poke 0xc920 80; poke 0xc930 $view
}
after time 10 {set ::videosource GFX9000;setup 0}
after time 10.2 {set ::fx [peek 0xc85e];set ::fy [peek 0xc86d];screenshot -raw "$::out/front.png";setup 1}
after time 10.4 {set ::rx [peek 0xc85e];set ::ry [peek 0xc86d];screenshot -raw "$::out/right.png";setup 2}
after time 10.6 {set ::lx [peek 0xc85e];set ::ly [peek 0xc86d];screenshot -raw "$::out/left.png";setup 3}
after time 10.8 {
    set f [open "$::out/result.txt" w]
    puts $f "$::fx $::fy $::rx $::ry $::lx $::ly [peek 0xc85e] [peek 0xc86d]"
    close $f; screenshot -raw "$::out/back.png";exit
}
