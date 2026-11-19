set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
proc setup {player cpu face} {
 poke 0xc800 0;poke 0xc801 $player;poke 0xc809 $face;poke 0xc813 $cpu
 poke 0xc803 18;poke 0xc804 0;poke 0xc805 0;poke 0xc80c 8
 poke 0xc80d 43;poke 0xc80e 200;poke 0xc810 0;poke 0xc814 0;poke 0xc81e 0
 poke 0xc822 0;poke 0xc823 0;poke 0xc826 0
}
after time 10 {setup 140 100 1}
after time 10.12 {set ::far_left [peek 0xc80c];setup 123 100 1}
after time 10.24 {set ::near_left [peek 0xc80c];setup 124 100 1}
after time 10.36 {set ::edge_left [peek 0xc80c];setup 60 100 0}
after time 10.48 {set ::near_right [peek 0xc80c];setup 59 100 0}
after time 10.60 {set ::far_right [peek 0xc80c];setup 77 100 1}
after time 10.72 {set ::away [peek 0xc80c];set f [open "$out/hit-range.txt" w];puts $f "$::far_left $::near_left $::edge_left $::near_right $::far_right $::away";close $f;exit}
after time 14 {exit 1}
