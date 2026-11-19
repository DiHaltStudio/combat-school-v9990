# Start the integrated shooting code once the cartridge has finished booting.
proc launch_step6_when_ready {} {
 if {[peek 0xc0b3]==1} {
  poke 0xc736 0
  if {[peek 0x002b]&128} {poke 0xc734 50} else {poke 0xc734 60}
  reg PC 0x400a
  return
 }
 after frame launch_step6_when_ready
}
after time 1 launch_step6_when_ready
