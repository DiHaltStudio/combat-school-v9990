set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::sample 0
proc capture {} {
 incr ::sample
 # Hold the enemy behind the crates and keep the player's jump active.
 poke 0xc911 1;poke 0xc912 248;poke 0xc913 2;poke 0xc915 0;poke 0xc91c 200
 poke 0xc857 255
 if {$::sample>4} {
  set ::videosource GFX9000
  screenshot -raw [format "%s/%02d.png" $::out [expr {$::sample-5}]]
 }
 if {$::sample>=64} {exit}
 after frame capture
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc840 208;poke 0xc841 2;poke 0xc801 96;poke 0xc800 0
 poke 0xc856 8;poke 0xc823 0;poke 0xc851 5;poke 0xc871 5
 poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc891 4;poke 0xc8da 1;poke 0xc8e0 1;poke 0xc8e9 0
 poke 0xc930 1;poke 0xc911 1;poke 0xc912 248;poke 0xc913 2;poke 0xc921 0
 poke 0xc8ad 8;poke 0xc900 0;poke 0xc990 0;poke 0xc804 32;poke 0xc803 0
 after frame capture
}
after time 10 {after frame ready}
after time 30 {exit 1}
