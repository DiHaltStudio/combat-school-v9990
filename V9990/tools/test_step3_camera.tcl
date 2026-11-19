set throttle off
after time 12 {
    set result [peek 0xc700]
    set out [open $::env(STEP3_CAMERA_RESULT) w]
    puts $out $result
    close $out
    exit
}
