# Standalone penalty (five chin-ups). PENALTY_MODE=win: fast presses of space
# from 15.5 s, screenshots while pulling and after the last chin-up;
# PENALTY_MODE=lose: no presses, screenshots of the fall and GAME OVER.
# Logs phase, count, height, lowering and the clock for every screenshot.
set throttle off
catch {set vsync off}   ;# a hidden window must not hold the emulation back
set out $::env(PENALTY_OUT)
set ::pmode $::env(PENALTY_MODE)
file mkdir $out
proc shot {name} {
 set ::videosource GFX9000
 # The first screenshot after selecting the V9990 output can fail: retry.
 if {[catch {screenshot -raw "$::out/$name.png"}]} {after time 0.1 [list shot $name]; return}
 set f [open "$::out/log.txt" a]
 puts $f "$name phase=[peek 0xf276] count=[peek 0xf201] height=[peek 0xf27b] lower=[peek 0xf27c] clock=[peek 0xf27f].[peek 0xf280]"
 close $f
}
set ::pressed 0
proc tap {} {
 set p [peek 0xf276]
 if {$p==2 || $p==3} {keymatrixup 8 1;return}
 if {$::pressed} {keymatrixup 8 1;set ::pressed 0} else {keymatrixdown 8 1;set ::pressed 1}
 after time 0.07 tap
}
after time 9 {shot portrait}
after time 13.5 {shot intro}
if {$::pmode eq "win"} {
 after time 15.5 {tap}
 foreach t {23 25} {after time $t "shot play$t"}
 proc finished {} {
  if {[peek 0xf276]==2} {
   foreach d {0.5 2.2 5.2 6.2 8} {after time $d "shot end$d"}
   after time 9 exit
   return
  }
  after frame finished
 }
 after time 16 finished
} else {
 foreach t {35 37 38.5 41 44} {after time $t "shot end$t"}
 after time 45 exit
}
after time 60 {exit 1}
