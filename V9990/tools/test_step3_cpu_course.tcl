set throttle off
after time 10 {poke 0xc702 0;poke 0xc703 0;poke 0xc713 0;poke 0xc73b 0;poke 0xc730 0;poke 0xc731 60;poke 0xc735 0}
after time 30 {set ::p20 [expr {[peek 0xc702]+256*[peek 0xc703]}];set ::stun [peek 0xc713]}
after time 65 {set f [open $::env(STEP3_CPU_COURSE_RESULT) w]; puts $f "$::p20 [expr {[peek 0xc702]+256*[peek 0xc703]}] $::stun"; close $f;exit}
