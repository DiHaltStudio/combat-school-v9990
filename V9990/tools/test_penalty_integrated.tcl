# Penalty in the cartridge. PEN_CASE:
#   step1win   Step 1: one second left, runner 84 pixels from the line (7
#              chin-ups); presses during the chin-ups; expects Step 2 (c418=4)
#              with 0:35 (c417) and the penalty used.
#   step1then2 step1win, then Step 2 lost by the clock with 38 hits: GAME
#              OVER and the title (the penalty must not corrupt pen_try).
#   step1lose  the same without presses: GAME OVER, then the title (c0b3=1)
#              with the penalty available again.
#   step2      Step 2 from the title with two seconds and 42 hits of 44 (8
#              chin-ups, step 2).
#   step2far   the same with 10 hits: no penalty, GAME OVER and the title.
#   step2used  42 hits with the penalty already used: GAME OVER, title.
#   step4over  Step 4 (bank 77) with the penalty used and no shots: GAME
#              OVER and the title instead of repeating Step 4.
#   step7over  Step 7 (bank 55) without input, lost to the instructor:
#              GAME OVER and the title.
# Writes PEN_OUT/result.txt: case, penalty step and count, and the outcome.
set throttle off
catch {set vsync off}
set out $::env(PEN_OUT)
set case $::env(PEN_CASE)
file mkdir $out
set ::count 0; set ::step 0; set ::armed 0
# lost.png: the lost step's own screen, 2 s into pen_try's 5-second wait.
set ::lostshot 0
proc lost_watch {} {
 if {!$::lostshot && [peek 0xf206]==1} {set ::lostshot 1; after time 2 {shot lost}; return}
 after frame lost_watch
}
after time 1 lost_watch
proc finish {text} {
 set f [open "$::out/result.txt" w]; puts $f "$::case $::step $::count $text"; close $f
 set ::videosource GFX9000
 catch {screenshot -raw "$::out/end.png"}
 exit
}
proc shot {name} {
 set ::videosource GFX9000
 # The first screenshot after selecting the V9990 output can fail: retry.
 if {[catch {screenshot -raw "$::out/$name.png"}]} {after time 0.1 [list shot $name]}
}
set ::pressed 0
set ::over 0
proc over {} {
 if {[peek 0xc0b3]==1} {finish "title over=$::over used=[peek 0xf200]"; return}
 if {[peek 0xc418]==4 && [peek 0xc435]>3} {finish "restarted used=[peek 0xf200]"; return}
 if {[peek 0xf276]==4 && [peek 0xf202]==2 && $::over==2} {set ::over 1; after time 2 {shot gameover}}
 after frame over
}
proc tap {} {
 set p [peek 0xf276]
 if {$p==2 || $p==3} {keymatrixup 8 1;return}
 if {$::pressed} {keymatrixup 8 1;set ::pressed 0
set ::over 0
proc over {} {
 if {[peek 0xc0b3]==1} {finish "title over=$::over used=[peek 0xf200]"; return}
 if {[peek 0xc418]==4 && [peek 0xc435]>3} {finish "restarted used=[peek 0xf200]"; return}
 if {[peek 0xf276]==4 && [peek 0xf202]==2 && $::over==2} {set ::over 1; after time 2 {shot gameover}}
 after frame over
}} else {keymatrixdown 8 1;set ::pressed 1}
 after time 0.07 tap
}
# Step 1: once the race runs, leave one second and move the runner forward.
proc race {} {
 if {[peek 0xc0ba]==0 && [peek 0xc0d0]>2 && [peek 0xc0d0]<60 && [peek 0xc0d9]==0} {
  poke 0xc0d0 1; poke 0xc00c 9; poke 0xc006 16; poke 0xc000 100
  after time 0.5 watch
  return
 }
 after frame race
}
proc watch {} {
 if {[peek 0xf200]==1 && !$::armed} {
  set ::armed 1; set ::count [peek 0xf201]; set ::step [peek 0xf202]
  after time 6 {shot portrait}
  if {$::case ne "step1lose"} {after time 11 tap; after time 13 {shot chinups}}
 }
 if {$::armed} {
  if {$::case eq "step1lose" && [peek 0xc0b3]==1} {finish "title used=[peek 0xf200]"; return}
  if {$::case eq "step1then2" && [peek 0xc418]==4 && [peek 0xf200]==1 && !$::over} {
   set ::over 1
   after time 2 {poke 0xc434 38; poke 0xc435 2; set ::over 2; over}
   return
  }
  if {$::case eq "step1win" && [peek 0xc418]==4 && [peek 0xf200]==1} {after time 1 {finish "step2 time=[peek 0xc417] used=[peek 0xf200]"}; return}
  if {$::case eq "step2" && [peek 0xc418]==7} {after time 1 {finish "step3 time=[peek 0xc731] used=[peek 0xf200]"}; return}
  if {[peek 0xf276]==3 && $::case eq "step1lose"} {after time 7 {shot gameover}}
 }
 after frame watch
}
if {$case eq "step4over" || $case eq "step7over"} {
 set ::over 0
 set ::lost [expr {$case eq "step4over" ? 4 : 7}]
 proc launch {} {
  if {[peek 0xc0b3]==1} {
   set bank [expr {$::lost==4 ? 77 : 55}]
   poke 0xc734 [expr {[peek 0x002b]&128 ? 50 : 60}]
   poke 0xc736 0; poke 0xc43f 0; poke 0xc0b3 0; poke 0xf200 1
   # ld a,bank / ld (0x6000),a / jp 0x4010
   set a 0xca80
   foreach b [list 0x3e $bank 0x32 0x00 0x60 0xc3 0x10 0x40] {poke $a $b; incr a}
   reg PC 0xca80
   after time 2 over
   return
  }
  after frame launch
 }
 proc over {} {
  if {[peek 0xc0b3]==1} {finish "title over=$::over used=[peek 0xf200]"; return}
  if {[peek 0xf276]==4 && [peek 0xf202]==$::lost && !$::over} {set ::over 1; after time 2 {shot gameover}}
  after frame over
 }
 after time 1 launch
} elseif {$case eq "step2far" || $case eq "step2used"} {
 proc launch {} {
  if {[peek 0xc0b3]==1} {
   poke 0xc0dd [expr {[peek 0x002b]&128 ? 50 : 60}]
   poke 0xc417 2
   poke 0xc0b3 0
   reg PC 0x400d
   after time 1 {
    poke 0xc434 [expr {$::case eq "step2far" ? 10 : 42}]
    if {$::case eq "step2used"} {poke 0xf200 1}
    over
   }
   return
  }
  after frame launch
 }
 # GAME OVER (module running: bank 123 in page 1), then the title.
 proc over {} {
  if {[peek 0xc0b3]==1} {finish "title over=$::over used=[peek 0xf200]"; return}
  if {[peek 0xf276]==4 && [peek 0xf202]==2 && !$::over} {set ::over 1; after time 2 {shot gameover}}
  after frame over
 }
 set ::over 0
 after time 1 launch
} elseif {$case eq "step2"} {
 proc launch {} {
  if {[peek 0xc0b3]==1} {
   poke 0xc0dd [expr {[peek 0x002b]&128 ? 50 : 60}]
   poke 0xc417 2
   poke 0xc0b3 0          ;# leave the title: test_skip_intro.tcl presses space there
   reg PC 0x400d
   after time 1 {poke 0xc434 42; watch}
   return
  }
  after frame launch
 }
 after time 1 launch
} else {
 after time 1 race
}
after time 240 {finish "timeout stage=[peek 0xc418] phase=[peek 0xf276]"}
