set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc record {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[expr {[peek 0xc840]+256*[peek 0xc841]+[peek 0xc801]}] [peek 0xc8dd] [peek 0xc804] [peek 0xc856] [peek 0xc809] [peek 0xc8de] [peek 0xc8df]"
 close $f
}
proc caught {} {
 if {[peek 0xc8dd]==1} {
  keymatrixup 4 4
  record caught
  # No knife throwers (doorway, C910): this scenario isolates hanging controls
  # here. Again a frame later: a poke during the record swap is undone.
  poke 0xc990 [expr {[peek 0xc990]|16}];poke 0xc951 5;poke 0xc911 5
  after frame {poke 0xc911 5;poke 0xc951 5}
  # Place a live ground fire directly below the hanging player.
  set world [expr {[peek 0xc840]+256*[peek 0xc841]+[peek 0xc801]+24}]
  poke 0xc8a0 [expr {$world & 255}];poke 0xc8a1 [expr {$world >> 8}]
  poke 0xc8a2 3;poke 0xc8b5 180
  after time 0.3 {
   set ::videosource GFX9000
   screenshot -raw "$::out/hanging.png"
   record idle
   # A ground assailant directly underneath must not kill a hanging player.
   poke 0xc851 1
   set ex [expr {[peek 0xc840]+256*[peek 0xc841]+[peek 0xc801]}]
   poke 0xc852 [expr {$ex & 255}];poke 0xc853 [expr {$ex >> 8}]
   after time 0.3 {
   record under
   poke 0xc851 5
   keymatrixdown 8 16
   after time 1 {
    keymatrixup 8 16;record moved
    after time 0.4 {
     record stopped
     keymatrixdown 8 128
     after time 0.5 {
      keymatrixup 8 128;record right
      keymatrixdown 4 4
      after time 0.15 {keymatrixup 4 4}
      after time 0.4 {record dropped;exit}
     }
    }
   }
   }
  }
  return
 }
 after frame caught
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 13;poke 0xc8e0 1;poke 0xc8e9 0;poke 0xc930 1;poke 0xc911 5;poke 0xc921 5;poke 0xc8a2 0;poke 0xc8da 1
 poke 0xc840 50;poke 0xc841 2;poke 0xc800 0;poke 0xc801 96
 poke 0xc856 8;poke 0xc823 0;poke 0xc804 0;poke 0xc806 0;poke 0xc8d4 2
 after time 0.2 {keymatrixdown 4 4;after frame caught}
}
after time 10 {after frame ready}
after time 30 {exit 1}
