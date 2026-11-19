set throttle off
set ::n -1
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc sample {} {
 for {set row 0} {$row<11} {incr row} {keymatrixup $row 255}
 if {$::n<0} {
  if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {debug cont;return}
  set ::n 0
  foreach a {0xc851 0xc871 0xc891 0xc8c1 0xc8e9 0xc911 0xc921 0xc941 0xc951 0xc961 0xc971} {poke $a 5}
  foreach a {0xc8a2 0xca02 0xc8dd 0xc8d4 0xc823 0xc803 0xc981} {poke $a 0}
  poke 0xc8da 1;poke 0xc8d0 1;poke 0xc930 1;poke 0xc8e0 1;poke 0xc900 1;poke 0xc990 49
 } else {incr ::n}
 set i [expr {$::n/4}];set mode [expr {$i/19}];set step [expr {$i%19}]
 if {$mode==4} {exit;return}
 set x [expr {$mode%2==0 ? 1328+4*$step : 1400-4*$step}]
 set camera 1220
 poke 0xc840 [expr {$camera&255}];poke 0xc841 [expr {$camera>>8}]
 poke 0xc801 [expr {$x-$camera-32}];poke 0xc809 [expr {$mode%2==0?0:1}]
 poke 0xc856 8;poke 0xc857 40
 if {$mode>=2} {poke 0xc804 20;poke 0xc80a 32} else {poke 0xc804 0;poke 0xc80a 0}
 if {$::n%4==3} {
  foreach {name device start size} {vram "Sunrise GFX9000 VRAM" 0 524288 regs "Sunrise GFX9000 regs" 0 64 ram memory 0xc800 2048} {
   set f [open "$::out/$i-$name.bin" wb];puts -nonewline $f [debug read_block $device $start $size];close $f
  }
 }
 debug cont
}
proc safe_sample {} {if {[catch {sample} message]} {puts stderr "FAIL $message";exit 1}}
debug set_bp $::env(MISSION_LOOP) {} safe_sample
after time 60 {exit 1}
