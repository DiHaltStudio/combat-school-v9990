set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
set ::frame 0
set ::starts 0
set ::previous 0
proc repeated_kicks {} {
 incr ::frame
 if {$::frame%4==1} {keymatrixdown 8 1} else {keymatrixup 8 1}
 set attack [peek 0xc803]
 if {$attack>$::previous} {incr ::starts}
 set ::previous $attack
 if {$::frame>=110} {
  keymatrixup 8 1
  set f [open "$::out/repeat.txt" w]
  puts $f "$::starts [peek 0xc813] [peek 0xc80c] [peek 0xc80b] [peek 0xc814]"
  close $f;exit
 }
 after frame repeated_kicks
}
# Skip the arcade READY (2.1 s) so that the fight is running.
after time 9.9 {poke 0xc849 0}
after time 10 {poke 0xc800 0;poke 0xc801 70;poke 0xc809 0;poke 0xc813 100;poke 0xc80b 8;poke 0xc80c 8;poke 0xc80d 0;poke 0xc80e 100;poke 0xc803 0;poke 0xc805 0;poke 0xc81e 0;poke 0xc814 0;poke 0xc822 0;poke 0xc826 0;after frame repeated_kicks}
after time 14 {exit 1}
