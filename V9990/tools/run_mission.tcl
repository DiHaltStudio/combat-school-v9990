# Play the final mission on the full cartridge (make run-mission): from the
# title, start Step 6 and end it at once, win the instructor fight at once
# with 200000 points carried from the earlier steps, then the ceremony, the
# rank, the map and the two screens before the mission go by at full speed
# (as in tools/test_mission_integrated.tcl). Normal speed once it starts.
# make run-msx-flag uses the same route and slows down at the ceremony.
set throttle off
set ::combat 0
set ::rank 0
set ::preview_msx_flag [info exists ::env(PREVIEW_MSX_FLAG)]

# Use the real F1 shortcut on the cover before skipping ahead.
proc mission_preview_cover {} {
 if {[debug read "Sunrise GFX9000 regs" 6] != 0x96 ||
     !([debug read "Sunrise GFX9000 regs" 8] & 0x80)} {
  after frame mission_preview_cover
  return
 }
 after time 0.10 {
  keymatrixdown 6 32
  keymatrixdown 8 1
  after time 0.15 {
   keymatrixup 6 32
   keymatrixup 8 1
   mission_launch
  }
 }
}

proc mission_launch {} {
 if {[peek 0xc0b3] != 1} {
  after time 0.02 mission_launch
  return
 }
 if {$::preview_msx_flag && [peek 0xf207] != 1} {
  puts stderr "The cover did not select the MSX flag"
  exit 1
 }
 mission_enter_step6
}

proc mission_enter_step6 {} {
 poke 0xc736 0
 if {[peek 0x002b]&128} {poke 0xc734 50} else {poke 0xc734 60}
 reg PC 0x400a
 after time 1 {
  poke 0xc434 37; poke 0xc435 1
  set prev [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc0dd]-2)&65535}]
  poke 0xc436 [expr {$prev&255}]; poke 0xc437 [expr {$prev>>8}]
 }
 after time 0.02 mission_watch
}
proc mission_watch {} {
 if {[peek 0xc418]==21 && !$::combat} {
  set ::combat 1
  after time 1 {poke 0xc829 8; poke 0xc814 1; poke 0xc828 179}
  poke 0xc75c 0x40; poke 0xc75d 0x0d; poke 0xc75e 0x03
 }
 # Start at normal speed from the formation, with the music and before
 # the camera rises to the flag.
 if {$::preview_msx_flag && $::combat && [peek 0xc82a] == 2} {
  set ::throttle on
  return
 }
 if {$::combat && [peek 0xc82a]==4} {set ::rank 1}
 set left [expr {[peek 0xd001]+256*[peek 0xd002]}]
 if {$::rank && $left==0 && [peek 0xc856]==8 && [debug read "Sunrise GFX9000 regs" 8]==0xc2} {
  set ::throttle on              ;# normal speed at once: the first enemy
  catch mission_ready            ;# reaches the player within 3 s
  return
 }
 after time 0.02 mission_watch
}
if {$::preview_msx_flag} {
 after time 1 mission_preview_cover
} else {
 after time 1 mission_launch
}
