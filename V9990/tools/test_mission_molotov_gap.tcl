set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::started 0
set ::jumped 0
set ::frames 0
proc watch_crossing {} {
 incr ::frames
 poke 0xc857 255
 set projectile [peek 0xc8a2]
 set x [expr {[peek 0xc840]+256*[peek 0xc841]+[peek 0xc801]+32}]
 if {!$::started && $projectile==0} {
  set ::started 1
  keymatrixdown 8 16
 }
 if {$::started && !$::jumped && $x<=968 && [peek 0xc804]==0} {
  set ::jumped 1
  keymatrixdown 4 4
  after time 0.15 {keymatrixup 4 4}
 }
 if {$::started && ($x<873 || $projectile==1 || [peek 0xc856]==0)} {
  keymatrixup 8 16
  set f [open "$::out/result.txt" w]
  puts $f "$x $projectile [peek 0xc856] [peek 0xc8dc] $::jumped $::frames"
  close $f
  exit
 }
 after frame watch_crossing
}
proc setup {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame setup;return}
 poke 0xc851 5;poke 0xc871 5;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8
 poke 0xc840 72;poke 0xc841 3;poke 0xc801 130;poke 0xc856 8;poke 0xc823 0
 poke 0xc891 1;poke 0xc892 52;poke 0xc893 3;poke 0xc8da 1;poke 0xc8dc 0
 poke 0xc8a0 190;poke 0xc8a1 3;poke 0xc8d5 2;poke 0xc8a2 2;poke 0xc8b5 5;poke 0xc8b2 192
 after frame watch_crossing
}
after time 10 {after frame setup}
after time 45 {exit 1}
