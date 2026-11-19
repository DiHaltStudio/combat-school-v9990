# Arcade ending (src/mission_ending.asm) in the standalone mission: once the
# mission runs, the guardian counts as defeated with the arcade capture's
# score (304500) and the ending starts at once. Screenshots: the mansion
# 200 frames in, the officer rank screen 164 frames in, CONGRATULATIONS,
# the RANKING table 241 frames in (as arcade frames 9066, 9500, 10300 and
# 10700, tools/check_mission_ending.py), the initials C, C, D typed in
# the RANKING table, and the screen after the ending.
# <name>.txt holds the frames left when the screenshot was taken.
set throttle off
catch {set vsync off}
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::ending $::env(PRELUDE_ENDING)
set ::stage 0
proc shot {name value} {
 set ::videosource GFX9000
 if {[catch {screenshot -raw "$::out/$name.png"}]} {after time 0.1 [list shot $name $value]; return}
 set f [open "$::out/$name.txt" w]; puts $f $value; close $f
}
# Initials C, C, D: right twice, space, space (the next one starts on C),
# right, space. Cursor right: row 8 bit 7; space: row 8 bit 0.
proc press {mask t} {
 after time $t [list keymatrixdown 8 $mask]
 after time [expr {$t+0.1}] [list keymatrixup 8 $mask]
}
proc type_initials {} {
 press 0x80 0.3; press 0x80 0.6; press 0x01 0.9; press 0x01 1.2; press 0x80 1.5; press 0x01 1.8
 after time 2.3 {shot initials 0}
}
proc word {a} {expr {[peek $a]+256*[peek [expr {$a+1}]]}}
proc watch {} {
 set screen [word 0xd003]
 set pre [word 0xd001]
 set left [word 0xd0d9]
 set on [expr {[debug read "Sunrise GFX9000 regs" 8]==0xc2}]
 switch $::stage {
  0 {
   if {[peek 0xc856]==8 && [word 0xc840]>0 && $on} {
    # 304500 points; the guardian down, the ending one frame later.
    poke 0xc75c 0x74; poke 0xc75d 0xa5; poke 0xc75e 0x04
    poke 0xd0b8 1; poke 0xd0b9 0
    poke 0xc981 5
    set ::stage 1
   }
  }
  1 {if {$screen==$::ending && $pre>0 && $pre<=266} {shot mansion $pre; set ::stage 2}}
  2 {if {$left>0 && $left<=413 && $left>300} {shot rank $left; set ::stage 3}}
  3 {if {$left==0 && $on} {set ::stage 4; after time 3 {shot congrats 0; set ::stage 5}}}
  5 {if {$left>1000} {set ::stage 6}}
  6 {if {$left>0 && $left<=1039} {shot ranking $left; set ::stage 7; type_initials}}
  7 {if {$left==0} {set ::stage 8; after time 2 {shot after 0; after time 0.5 {
     set f [open "$::out/done.txt" w]; puts $f "[peek 0xf300][peek 0xf301] [peek 0xf305] [peek 0xf306] [peek 0xf307]"; close $f; exit}}}}
 }
 after frame watch
}
after time 1 watch
after time 200 {exit 1}
