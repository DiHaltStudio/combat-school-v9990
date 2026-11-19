# Doorway wall edge in front of the actors (src/mission_doorway.asm).
# At the main loop: player standing on the edge (camera 1229, player centre
# at world 1357), then the edge clipped at both screen sides. Dumps VRAM,
# V9990 registers and mission RAM for tools/check_mission_door_front.py.
set throttle off
catch {set vsync off}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::n -1
set ::cameras {1229 1102 1358 1229 361 229 495 495}
proc sample {} {
 if {$::n<0} {
  if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {debug cont;return}
  set ::n 0
  poke 0xc840 [expr {1229&255}];poke 0xc841 [expr {1229>>8}];poke 0xc801 96
 } else {
  incr ::n
  poke 0xc856 8;poke 0xc857 40
  set index [expr {$::n/12}]
  if {$::n%12==0} {
   if {$index>0} {
    foreach {name device start size} {vram "Sunrise GFX9000 VRAM" 0 524288 regs "Sunrise GFX9000 regs" 0 64 ram memory 0xc800 2048} {
     set f [open "$::out/$index-$name.bin" wb];puts -nonewline $f [debug read_block $device $start $size];close $f
    }
    if {$index==1} {set ::videosource GFX9000;screenshot -raw "$::out/door.png"}
    if {$index==5} {set ::videosource GFX9000;screenshot -raw "$::out/door2.png"}
   }
   if {$index==[llength $::cameras]-1} {exit;return}
   set cam [lindex $::cameras $index]
   poke 0xc840 [expr {$cam&255}];poke 0xc841 [expr {$cam>>8}]
   poke 0xc801 96
  }
 }
 debug cont
}
debug set_bp $::env(MISSION_LOOP) {} sample
after time 60 {exit 1}
