# Down crouches; down + button 1 is the sweeping kick and hits in range;
# button 1 alone remains the high kick (arcade, tools/mame_step7_kicks.lua).
set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
after time 9.8 {poke 0xc800 0;poke 0xc801 70;poke 0xc809 0;poke 0xc813 100;poke 0xc80c 8;poke 0xc810 0;poke 0xc80d 0;poke 0xc80e 120;keymatrixdown 8 64}
after time 10.2 {set ::crouch [peek 0xc840];keymatrixdown 8 1}
after time 10.3 {keymatrixup 8 1}
after time 10.4 {set ::low [peek 0xc841]}
after time 10.9 {set ::low_hp [peek 0xc80c];keymatrixup 8 64}
after time 11.5 {poke 0xc813 100;poke 0xc801 70;poke 0xc810 0;poke 0xc80e 120;keymatrixdown 8 1}
after time 11.6 {keymatrixup 8 1}
after time 11.7 {set ::high [peek 0xc841];set ::stand [peek 0xc840]}
after time 12.3 {
 set f [open "$out/lowkick.txt" w]
 puts $f "$::crouch $::low $::low_hp $::high $::stand [peek 0xc80c]"
 close $f;exit
}
after time 15 {exit 1}
