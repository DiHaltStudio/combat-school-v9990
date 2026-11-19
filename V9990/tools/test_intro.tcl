# Cartridge introduction (src/intro_slide.asm and the region engine,
# tools/build_intro_anim.py): SPACE on the title, then screenshots while
# NICK's portrait slides (frames left in the slide, D0FD) and during the
# runners and names (frames left of the screen, D001, with D003 =
# prelude_intro, PRELUDE_INTRO). <name>.txt holds the value when taken;
# tools/check_intro.py compares them with the arcade capture.
set throttle off
catch {set vsync off}
set ::out $::env(INTRO_OUT)
file mkdir $::out
set ::screen $::env(PRELUDE_INTRO)
set ::state 0
set ::taken {}
proc shot {name value} {
 set ::videosource GFX9000
 if {[catch {screenshot -raw "$::out/$name.png"}]} {after time 0.05 [list shot $name $value]; return}
 set f [open "$::out/$name.txt" w]; puts $f $value; close $f
}
proc word {a} {expr {[peek $a]+256*[peek [expr {$a+1}]]}}
proc watch {} {
 if {$::state==0 && [peek 0xc0b3]==1} {
  set ::state 1
  poke 0xd0fd 0
  keymatrixdown 8 1
  after time 0.15 {keymatrixup 8 1}
 }
 if {$::state==1 && [peek 0xc0b3]==2} {set ::state 2}
 if {$::state==2} {
  set slide [peek 0xd0fd]
  set left [word 0xd001]
  set here [expr {[word 0xd003]==$::screen}]
  foreach {name kind at} {slide-up s 70 slide-right s 20 names-a r 250 names-b r 60} {
   if {[lsearch $::taken $name]>=0} continue
   if {$kind eq "s" && $here && $left==0 && $slide<=$at && $slide>0} {lappend ::taken $name; shot $name $slide}
   if {$kind eq "r" && $here && $left<=$at && $left>0} {lappend ::taken $name; shot $name $left}
  }
  if {[llength $::taken]==4} {after time 0.5 exit; return}
  if {[peek 0xc0b3]==3} {exit 1}
 }
 after frame watch
}
after time 1 watch
after time 30 {exit 1}
