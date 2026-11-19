set throttle off
after time 9.8 {poke 0xc8d0 1;poke 0xc8c1 5}
after time 9.8 {poke 0xc8ad 8}
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
after time 9.8 {poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc856 8;poke 0xc823 0;poke 0xc857 0}
after time 10 {set ::x0 [expr {[peek 0xc800]+256*[peek 0xc801]}];keymatrixdown 8 128}
after time 10.8 {keymatrixup 8 128;set ::x1 [expr {[peek 0xc800]+256*[peek 0xc801]}];keymatrixdown 8 1}
after time 10.95 {set ::kick [peek 0xc803];keymatrixup 8 1}
after time 11.5 {keymatrixdown 4 4}
after time 11.65 {set ::jump [peek 0xc804];keymatrixup 4 4;set ::videosource GFX9000;screenshot -raw "$out/screen.png";set f [open "$out/result.txt" w];puts $f "$::x0 $::x1 $::kick $::jump $::videosource";close $f;exit}
after time 14 {exit 1}
