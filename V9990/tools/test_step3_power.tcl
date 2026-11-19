set throttle off
set ::out $::env(STEP3_POWER_OUT)
file mkdir $::out
after time 10 {set ::initial [peek 0xc710]; set ::videosource GFX9000}
after time 10.10 {keymatrixdown 8 1}
after time 10.20 {keymatrixup 8 1}
after time 10.30 {keymatrixdown 8 1}
after time 10.40 {keymatrixup 8 1}
after time 10.50 {keymatrixdown 8 1}
after time 10.60 {keymatrixup 8 1}
after time 10.65 {
    set f [open "$::out/result.txt" w]
    puts $f "$::initial [peek 0xc710]"
    close $f
    screenshot -raw "$::out/power.png"
    exit
}
