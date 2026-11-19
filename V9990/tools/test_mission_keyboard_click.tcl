set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 keymatrixdown 8 16
 after time 0.3 {
  keymatrixup 8 16
  set f [open "$::out/result.txt" w]
  puts $f "[peek 0xf3db] [peek 0xc856]"
  close $f
  exit
 }
}
after time 10 {after frame ready}
after time 25 {exit 1}
