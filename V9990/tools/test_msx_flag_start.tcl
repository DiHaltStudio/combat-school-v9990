set throttle off
proc wait_title {} {
 if {[peek 0xc0b3]!=1} {after frame wait_title;return}
 if {$::env(FLAG_TEST)==1} {keymatrixdown 6 32}
 keymatrixdown 8 1
 after time 0.15 {
  keymatrixup 6 32;keymatrixup 8 1
  set v [peek 0xf207]
  if {$v!=$::env(FLAG_TEST)} {puts stderr "FAIL flag $v";exit 1}
  set f [open "$::env(FLAG_RESULT)" w];puts $f $v;close $f;exit
 }
}
after time 1 wait_title
after time 30 {exit 1}
