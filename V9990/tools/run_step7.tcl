# Jump to the instructor fight on the full cartridge: once the title is up,
# start Step 6 and end it at once with 37 hits, so the bonus, the interlude
# and the map play before the fight (as in tools/test_step7_integrated.tcl).
proc launch_step7_when_ready {} {
 if {[peek 0xc0b3]==1} {
  poke 0xc736 0
  if {[peek 0x002b]&128} {poke 0xc734 50} else {poke 0xc734 60}
  reg PC 0x400a
  after time 1 {
   poke 0xc434 37; poke 0xc435 1
   set prev [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc0dd]-2)&65535}]
   poke 0xc436 [expr {$prev&255}]; poke 0xc437 [expr {$prev>>8}]
  }
  return
 }
 after frame launch_step7_when_ready
}
after time 1 launch_step7_when_ready
