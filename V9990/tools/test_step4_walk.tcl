set throttle off
set ::out $::env(STEP4_WALK_OUT)
file mkdir $::out
after time 10 {
 set ::videosource GFX9000
 poke 0xc8e4 0x00;poke 0xc8e5 0x06
 for {set i 0} {$i<16} {incr i} {poke [expr {0xc900+$i}] 0}
 poke 0xc800 110
 set ::start [peek 0xc800]
 keymatrixdown 8 128
}
after time 10.2 {set ::right [peek 0xc800];set ::rd [peek 0xc8f9];screenshot -raw "$::out/right.png"}
after time 10.3 {keymatrixup 8 128;keymatrixdown 8 16}
after time 10.5 {set ::left [peek 0xc800];set ::ld [peek 0xc8f9];screenshot -raw "$::out/left.png"}
after time 10.6 {
 keymatrixup 8 16
 set f [open "$::out/result.txt" w];puts $f "$::start $::right $::left $::rd $::ld";close $f;exit
}
