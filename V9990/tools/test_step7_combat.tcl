set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
# Skip the arcade READY (2.1 s) so that the fight is running.
after time 9.9 {poke 0xc849 0}
after time 10 {poke 0xc80d 0;poke 0xc813 140;set ::cpu_before [peek 0xc813]}
after time 10.8 {set ::cpu_after [peek 0xc813]}
after time 11 {poke 0xc800 0;poke 0xc801 70;poke 0xc809 0;poke 0xc813 100;poke 0xc80c 1;poke 0xc810 0;poke 0xc814 0;poke 0xc80d 0;poke 0xc80e 80;keymatrixdown 8 1}
after time 11.4 {keymatrixup 8 1;set ::win [peek 0xc814];set ::cpu_health [peek 0xc80c];set ::videosource GFX9000;screenshot -raw "$out/player-win.png"}
after time 12 {poke 0xc814 0;poke 0xc80b 1;poke 0xc80c 8;poke 0xc80f 0;poke 0xc804 0;poke 0xc803 0;poke 0xc813 100;poke 0xc80d 24;poke 0xc822 0;poke 0xc823 0;poke 0xc826 0}
after time 12.3 {set ::loss [peek 0xc814];set ::player_health [peek 0xc80b];screenshot -raw "$out/cpu-win.png";set f [open "$out/combat.txt" w];puts $f "$::cpu_before $::cpu_after $::win $::cpu_health $::loss $::player_health";close $f;exit}
after time 14 {exit 1}
