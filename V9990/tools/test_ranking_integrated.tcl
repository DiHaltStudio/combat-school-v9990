# RANKING table after GAME OVER in the cartridge (src/ranking.asm), over two
# games without switching off: Step 2 lost (10 hits, no penalty) with
# 45000 points (Step 1 bonus), initials A A A (space three times); back at
# the title a second game lost the same way with 60000 points, initials
# B B B (right,
# then space three times); a third game lost the same way without points
# (the score starts at zero in every game: nothing enters the table).
# Writes RANK_OUT/table.txt: the ten entries as
# "score glyph glyph glyph" lines, and screenshots of both tables.
set throttle off
catch {set vsync off}
set out $::env(RANK_OUT)
file mkdir $out
set ::game 0
proc shot {name} {
 set ::videosource GFX9000
 if {[catch {screenshot -raw "$::out/$name.png"}]} {after time 0.1 [list shot $name]}
}
proc press {mask t} {
 after time $t [list keymatrixdown 8 $mask]
 after time [expr {$t+0.1}] [list keymatrixup 8 $mask]
}
proc launch {} {
 if {[peek 0xc0b3]==1} {
  incr ::game
  poke 0xc0dd [expr {[peek 0x002b]&128 ? 50 : 60}]
  poke 0xc417 2
  poke 0xc0b3 0
  poke 0xd0e9 255
  reg PC 0x400d
  after time 1 {
   poke 0xc434 10
   # The Step 1 bonus (C414): Step 2's result makes it the game score.
   if {$::game==1} {poke 0xc414 [expr {45000&255}]; poke 0xc415 [expr {45000>>8}]; entry} \
   elseif {$::game==2} {poke 0xc414 [expr {60000&255}]; poke 0xc415 [expr {60000>>8}]; entry} \
   else {title}
  }
  return
 }
 after frame launch
}
proc entry {} {
 # The initials are being taken: D0E9 holds the table place.
 if {[peek 0xd0e9]<10 && [peek 0xd0de]==0 && [debug read "Sunrise GFX9000 regs" 8]==0xc2} {
  if {$::game==1} {
   press 0x01 0.5; press 0x01 0.8; press 0x01 1.1
  } else {
   press 0x80 0.5; press 0x01 0.8; press 0x01 1.1; press 0x01 1.4
  }
  after time 2.5 [list shot table$::game]
  after time 3 title
  return
 }
 after frame entry
}
proc title {} {
 if {[peek 0xc0b3]==1} {
  if {$::game==3} {
   set f [open "$::out/table.txt" w]
   puts $f "[peek 0xf300] [peek 0xf301]"
   for {set i 0} {$i<10} {incr i} {
    set a [expr {0xf302+7*$i}]
    puts $f "[expr {[peek $a]+256*[peek [expr {$a+1}]]+65536*[peek [expr {$a+2}]]}] [peek [expr {$a+3}]] [peek [expr {$a+4}]] [peek [expr {$a+5}]]"
   }
   close $f
   exit
  }
  launch
  return
 }
 after frame title
}
after time 1 launch
after time 400 {exit 1}
