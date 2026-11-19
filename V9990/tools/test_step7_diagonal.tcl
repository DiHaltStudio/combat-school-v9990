set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
proc reset_actor {} {poke 0xc800 0;poke 0xc801 90;poke 0xc803 0;poke 0xc804 0;poke 0xc805 0;poke 0xc806 0;poke 0xc808 0}
proc xpos {} {expr {[peek 0xc800]+256*[peek 0xc801]}}
after time 10 {reset_actor;keymatrixdown 8 128;keymatrixdown 4 4}
after time 10.1 {keymatrixup 8 128;keymatrixup 4 4;set ::right_start [xpos];set ::right_jump [peek 0xc804]}
after time 10.3 {set ::right_end [xpos]}
after time 11 {reset_actor;keymatrixdown 8 16;keymatrixdown 4 4}
after time 11.1 {keymatrixup 8 16;keymatrixup 4 4;set ::left_start [xpos];set ::left_jump [peek 0xc804]}
after time 11.3 {set ::left_end [xpos]}
after time 12 {reset_actor;keymatrixdown 4 4}
after time 12.1 {keymatrixup 4 4;set ::straight_start [xpos];set ::straight_jump [peek 0xc804]}
after time 12.3 {set ::straight_end [xpos];set f [open "$out/diagonal.txt" w];puts $f "$::right_start $::right_end $::right_jump $::left_start $::left_end $::left_jump $::straight_start $::straight_end $::straight_jump";close $f;exit}
after time 14 {exit 1}
