set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
set ::frame 0
proc pressure {} {
 incr ::frame
 if {$::frame%4==1} {keymatrixdown 8 1} else {keymatrixup 8 1}
 if {$::frame<350} {after frame pressure;return}
 keymatrixup 8 1
 set ::stationary_player [peek 0xc801]
 set ::stationary_cpu [peek 0xc813]
 set ::stationary_cpu_health [peek 0xc80c]
 set ::stationary_result [peek 0xc814]
 # Let the instructor start an unforced counterattack in close range.
 poke 0xc800 0;poke 0xc801 70;poke 0xc809 0;poke 0xc813 95
 poke 0xc80b 8;poke 0xc80c 8;poke 0xc803 0;poke 0xc805 0;poke 0xc81e 0
 poke 0xc80d 0;poke 0xc80e 0;poke 0xc80f 0;poke 0xc810 0
 poke 0xc814 0;poke 0xc822 0;poke 0xc823 0;poke 0xc826 0
 after time 0.65 {
  set f [open "$::out/pressure.txt" w]
  puts $f "$::stationary_player $::stationary_cpu $::stationary_cpu_health $::stationary_result [peek 0xc80b] [peek 0xc80d]"
  close $f;exit
 }
}
after time 10 {
 poke 0xc800 0;poke 0xc801 70;poke 0xc809 0;poke 0xc813 100
 poke 0xc80b 8;poke 0xc80c 8;poke 0xc80d 0;poke 0xc80e 100
 poke 0xc803 0;poke 0xc805 0;poke 0xc81e 0;poke 0xc814 0
 poke 0xc822 0;poke 0xc823 0;poke 0xc826 0
 after frame pressure
}
after time 21 {exit 1}
