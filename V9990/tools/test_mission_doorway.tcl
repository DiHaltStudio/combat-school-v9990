set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc state {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[peek 0xc8d0] [peek 0xc8c1] [peek 0xc8a2] [peek 0xc8b2] [peek 0xc856] [peek 0xc823] [peek 0xc8d5] [peek 0xc89c]";close $f
}
proc watch_projectile {} {
 if {![info exists ::captured_windup] && [peek 0xc89c]>=165} {
  set ::captured_windup 1
  state windup
  after time 0.08 {set ::videosource GFX9000;screenshot -raw "$::out/windup.png"}
 }
 if {[peek 0xc8a2]} {
  state projectile-start
  after time 0.12 {state projectile-rise;set ::videosource GFX9000;screenshot -raw "$::out/projectile.png"}
  return
 }
 after frame watch_projectile
}
after time 10 {
 set f [open "$out/initial-facing.txt" w];puts $f [peek 0xc809];close $f
 poke 0xc851 5;poke 0xc871 5;poke 0xc891 5;poke 0xc8ad 8
 poke 0xc8d0 0;poke 0xc8c1 0;poke 0xc8a2 0
 poke 0xc856 8;poke 0xc823 0;poke 0xc857 0
 poke 0xc840 26;poke 0xc841 4;poke 0xc801 96
}
after time 10.25 {state before;poke 0xc840 25}
after time 10.5 {state after;after frame watch_projectile}
after time 12.5 {state impact;exit}
after time 18 {exit 1}
