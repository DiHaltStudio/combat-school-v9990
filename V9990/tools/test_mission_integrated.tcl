# Final mission inside the game MegaROM: from Step 6 (as in
# tools/test_step7_integrated.tcl), win against the instructor at once, then
# the ceremony, the rank screen, the map, the two screens before the mission
# (src/mission_prelude.asm, mission banks 34..) and the mission start.
# path.txt: rank seen, ATTENTION seen, mansion seen, mission running,
# mission camera; screenshots of each step.
set throttle off
catch {set vsync off}
set out $::env(MISSION_INTEGRATED_OUT)
file mkdir $out
set ::att $::env(PRELUDE_ATTENTION)
set ::man $::env(PRELUDE_MANSION)
set ::combat 0; set ::rank 0; set ::attention 0; set ::mansion 0; set ::mission 0
proc shot {name} {
 set ::videosource GFX9000
 if {[catch {screenshot -raw "$::out/$name.png"}]} {after time 0.1 [list shot $name]}
}
after time 10 {
 poke 0xc736 0; poke 0xc734 50; reg PC 0x400a
}
after time 11 {
 poke 0xc434 37; poke 0xc435 1
 set prev [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc0dd]-2)&65535}]
 poke 0xc436 [expr {$prev&255}]; poke 0xc437 [expr {$prev>>8}]
}
proc watch {} {
 if {[peek 0xc418]==21 && !$::combat} {
  set ::combat 1
  after time 1 {poke 0xc829 8; poke 0xc814 1; poke 0xc828 179}
  # A known game score (200000) from the earlier steps, skipped here.
  poke 0xc75c 0x40; poke 0xc75d 0x0d; poke 0xc75e 0x03
 }
 if {$::combat && !$::rank && [peek 0xc82a]==4} {set ::rank 1; after time 1 {shot rank}}
 set screen [expr {[peek 0xd003]+256*[peek 0xd004]}]
 set left [expr {[peek 0xd001]+256*[peek 0xd002]}]
 if {$::rank && $screen==$::att && $left>0 && $left<200 && !$::attention} {set ::attention 1; shot attention}
 if {$::rank && $screen==$::man && $left>0 && $left<200 && !$::mansion} {set ::mansion 1; shot mansion}
 if {$::mansion && !$::mission && $left==0 && [peek 0xc856]==8 && [debug read "Sunrise GFX9000 regs" 8]==0xc2} {
  set ::mission 1
  after time 2 {
   shot mission
   after time 0.5 {
    set f [open "$::out/path.txt" w]
    puts $f "$::rank $::attention $::mansion $::mission [expr {[peek 0xc840]+256*[peek 0xc841]}]"
    close $f
    if {![info exists ::env(MISSION_ENDING)]} {exit}
    # The ending (src/mission_ending.asm): the guardian down at once, with
    # the score carried from the earlier steps; then the cartridge title.
    set ::score [expr {[peek 0xc75c]+256*[peek 0xc75d]+65536*[peek 0xc75e]}]
    poke 0xd0b8 1; poke 0xd0b9 0; poke 0xc981 5
    after frame ending_watch
   }
  }
  return
 }
 after frame watch
}
after time 11.1 watch
set ::ranking 0
proc ending_watch {} {
 set left [expr {[peek 0xd0d9]+256*[peek 0xd0da]}]
 if {$left>1000 && !$::ranking} {set ::ranking 1}
 if {$::ranking==1 && $left==0} {set ::ranking 2; poke 0xc0b3 0}
 if {$::ranking==2 && [peek 0xc0b3]==1} {
  # The title is ready (test_skip_intro.tcl then starts a new game).
  after time 0.1 {
   shot title
   after time 0.5 {
    set f [open "$::out/ending.txt" w]
    puts $f "$::score [peek 0xf300] [peek 0xf301] [expr {[peek 0xf302]+256*[peek 0xf303]+65536*[peek 0xf304]}]"
    close $f
    exit
   }
  }
  return
 }
 after frame ending_watch
}
after time [expr {[info exists ::env(MISSION_ENDING)] ? 260 : 150}] {exit 1}
