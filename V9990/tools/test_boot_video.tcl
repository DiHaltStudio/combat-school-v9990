set throttle off
after time 2 {set ::boot_source $videosource}
after time 12 {
    set f [open $::env(VIDEO_OUT) w]
    puts $f "$::boot_source $videosource [peek 0xc0b3]"
    close $f
    exit
}
