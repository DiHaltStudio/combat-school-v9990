set throttle off
set ::out $::env(STEP4_WAVES_OUT)
file mkdir $::out
set ::values {}
proc clear_wave {} {for {set i 0} {$i<8} {incr i} {poke [expr {0xc840+$i}] 0}}
proc collect {} {
    set count 0
    for {set i 0} {$i<8} {incr i} {if {[peek [expr {0xc840+$i}]]>0} {incr count}}
    lappend ::values $count [peek 0xc865] [peek 0xc848] [peek 0xc850]
    if {$count==8} {screenshot -raw "$::out/formation.png"}
    poke 0xc866 254
}
after time 10 {set ::videosource GFX9000;poke 0xc85a 0;poke 0xc866 254;clear_wave}
after time 10.15 collect
after time 10.30 collect
after time 10.45 collect
after time 10.60 collect
after time 10.75 collect
after time 10.90 collect
after time 11.05 collect
after time 11.20 {
    collect
    set f [open "$::out/result.txt" w];puts $f $::values;close $f;exit
}
