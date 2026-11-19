set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
set ::frame 0
set ::side right
proc reset_fight {player cpu facing} {
 poke 0xc800 0;poke 0xc801 $player;poke 0xc809 $facing;poke 0xc813 $cpu
 foreach a {0xc803 0xc804 0xc805 0xc80d 0xc80f 0xc810 0xc814 0xc81e 0xc822 0xc823 0xc826 0xc827} {poke $a 0}
 poke 0xc80b 8;poke 0xc80c 8;poke 0xc80e 100
}
proc repeat_corner {} {
 incr ::frame
 if {$::frame%4==1} {keymatrixdown 8 1} else {keymatrixup 8 1}
 if {$::frame<160} {after frame repeat_corner;return}
 keymatrixup 8 1
 if {$::side eq "right"} {
  set ::right_player [peek 0xc80b];set ::right_cpu [peek 0xc80c]
  set ::side left;set ::frame 0
  reset_fight 46 24 1
  after frame repeat_corner
 } else {
  set f [open "$::out/corner.txt" w]
  puts $f "$::right_player $::right_cpu [peek 0xc80b] [peek 0xc80c]"
  close $f;exit
 }
}
after time 10 {reset_fight 145 170 0;after frame repeat_corner}
after time 20 {exit 1}
