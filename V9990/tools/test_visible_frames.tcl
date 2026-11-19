set throttle off
after time 1 {set videosource GFX9000}
set ::i 0
proc capture_frame {} {
 screenshot -raw [format "%s/%03d.png" $::env(FRAMES_OUT) $::i]
 incr ::i
 if {$::i>=40} {exit}
 after time 0.033333 capture_frame
}
after time 12 capture_frame
