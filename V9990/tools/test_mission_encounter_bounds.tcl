set throttle off
set ::n -1
set ::knives 0
file mkdir $::env(MISSION_TEST_OUT)
set ::timing [open "$::env(MISSION_TEST_OUT)/timing.txt" w]
proc word {addr value} {poke $addr [expr {$value&255}];poke [expr {$addr+1}] [expr {$value>>8}]}
proc value {addr} {expr {[peek $addr]+256*[peek [expr {$addr+1}]]}}
proc sample {} {
 for {set row 0} {$row<11} {incr row} {keymatrixup $row 255}
 if {$::n<0} {
  if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {debug cont;return}
  set ::n 0
  foreach addr {0xc851 0xc871 0xc891 0xc8c1 0xc8e1 0xc911 0xc921 0xc971} {poke $addr 5}
  foreach addr {0xc8a2 0xca02 0xc8ed 0xc8d4 0xc823 0xc820 0xc803 0xc804 0xc80a 0xc981} {poke $addr 0}
  poke 0xc8da 1;poke 0xc8d0 1;poke 0xc930 1;poke 0xc8e0 1;poke 0xc8e9 5;poke 0xc900 1;poke 0xc990 49
  word 0xc972 0;poke 0xc97f 8
  foreach base {0xc940 0xc950} {
   for {set i 0} {$i<16} {incr i} {poke [expr {$base+$i}] 0}
   poke [expr {$base+1}] 1
  }
  word 0xc942 850;word 0xc952 461
  word 0xc840 620;poke 0xc801 96;poke 0xc8dd 1
  set ::previous 850
 } else {incr ::n}
 puts $::timing "$::n [machine_info time]"
 if {[value 0xc952]!=461} {error "doorway thrower moved at $::n"}
 set x [value 0xc942]
 if {$x<680 || $x>886} {error "attacker crossed a crate: $x"}
 if {$::n>0 && $x!=$::previous} {
  set expected [expr {$x<$::previous?1:0}]
  if {[peek 0xc94a]!=$expected} {error "wrong walking direction at $::n"}
 }
 set ::previous $x
 if {[peek 0xc8a2]==1 || [peek 0xca02]==1} {incr ::knives}
 if {$::n in {40 280}} {
  foreach {name device start size} {vram "Sunrise GFX9000 VRAM" 0 524288 regs "Sunrise GFX9000 regs" 0 64 ram memory 0xc800 2048} {
   set f [open "$::env(MISSION_TEST_OUT)/$::n-$name.bin" wb];puts -nonewline $f [debug read_block $device $start $size];close $f
  }
 }
 # The player left of the crates, the attacker still on screen (actors
 # far behind the camera wait: mission_far_behind).
 if {$::n==60} {word 0xc840 596;poke 0xc801 0}
 if {$::n==259 && $x!=850} {error "bottle thrower left its post: $x"}
 if {$::n==260} {word 0xc840 720}
 if {$::n==300} {word 0xc840 1100}
 if {$::n==500 && $x!=850} {error "bottle thrower left its post"}
 if {$::n<510} {poke 0xc857 100;poke 0xc856 8;poke 0xc8dd 1}
 if {$::n==510} {
  # Orange door guard must still attack when approached on the ground.
  word 0xc840 400;poke 0xc801 96;poke 0xc8dd 0;poke 0xc857 0;poke 0xc8d4 0
 }
 if {$::n==511} {
  if {$::knives==0} {error "stationary blue never threw knives"}
  close $::timing
  set f [open "$::env(MISSION_TEST_OUT)/result.txt" w];puts $f "OK: fixed doorway thrower, knife throwing, bottle thrower kept at its post";close $f
  exit;return
 }
 debug cont
}
proc safe_sample {} {if {[catch {sample} message]} {puts stderr "FAIL: $message";exit 1}}
debug set_bp $::env(MISSION_LOOP) {} safe_sample
after time 35 {exit 1}
