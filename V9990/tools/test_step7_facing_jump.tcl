# Arcade (16-nov): the player faces the instructor; LEFT steps back (C851)
# without turning round, and the jump keeps that facing.
set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
after time 10 {keymatrixdown 8 16}
after time 10.15 {set ::back [peek 0xc851];keymatrixup 8 16;set ::left [peek 0xc809]}
after time 10.3 {set ::left_after_release [peek 0xc809];set ::videosource GFX9000;screenshot -raw "$out/facing-left.png";keymatrixdown 8 128}
after time 10.45 {keymatrixup 8 128;set ::right [peek 0xc809];keymatrixdown 4 4}
after time 10.55 {keymatrixup 4 4}
after time 10.67 {set ::height [peek 0xc80a];set ::active [peek 0xc804];screenshot -raw "$out/jump-apex.png";set f [open "$out/facing-jump.txt" w];puts $f "$::left $::left_after_release $::right $::height $::active $::back";close $f;exit}
after time 14 {exit 1}
