set throttle off
set ::out $::env(STEP3_VISUAL_OUT)
file mkdir $::out
after time 10 {
    set ::before_player [expr {[peek 0xc700] + 256*[peek 0xc701]}]
    set ::before_cpu [expr {[peek 0xc702] + 256*[peek 0xc703]}]
    keymatrixdown 8 1
}
after time 12 {
    keymatrixup 8 1
    set file [open "$::out/result.txt" w]
    puts $file "$::before_player $::before_cpu [expr {[peek 0xc700]+256*[peek 0xc701]}] [expr {[peek 0xc702]+256*[peek 0xc703]}] $::videosource"
    close $file
    screenshot -raw "$::out/screen.png"
    exit
}
