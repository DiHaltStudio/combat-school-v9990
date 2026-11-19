set throttle off

proc on_cover {} {
 expr {[debug read "Sunrise GFX9000 regs" 6] == 0x96 &&
       ([debug read "Sunrise GFX9000 regs" 8] & 0x80)}
}

proc wait_cover {} {
 if {![on_cover]} {after frame wait_cover; return}
 after time 0.10 {
  if {$::env(FLAG_TEST) == 1} {
   keymatrixdown 6 32
   after time 0.15 {
    if {![on_cover] || [peek 0xf207] != 0} {error "F1 alone dismissed the cover"}
    leave_cover
   }
  } else {
   leave_cover
  }
 }
}

proc leave_cover {} {
 # A second key other than SPACE or RETURN also dismisses the cover.
 keymatrixdown 2 64
 after time 0.15 {
  keymatrixup 2 64
  keymatrixup 6 32
  wait_title
 }
}

proc wait_title {} {
 if {[peek 0xc0b3] != 1} {after frame wait_title; return}
 if {[peek 0xf207] != $::env(FLAG_TEST)} {error "Wrong flag selected on cover"}
 # F1 at the title cannot change the power-on selection.
 if {$::env(FLAG_TEST) == 0} {keymatrixdown 6 32}
 poke 0xd0fe 0xa5
 keymatrixdown 8 1
 after time 0.15 {
  keymatrixup 6 32
  keymatrixup 8 1
  check_started
 }
}

proc check_started {} {
 if {[peek 0xc0b3] != 3} {after frame check_started; return}
 set v [peek 0xf207]
 if {$v != $::env(FLAG_TEST)} {error "Wrong flag after starting the game"}
 set f [open $::env(FLAG_RESULT) w]
 puts $f $v
 close $f
 exit
}

after time 1 wait_cover
after time 30 {exit 1}
