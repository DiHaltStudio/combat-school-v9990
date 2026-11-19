set throttle off
set ::n -1
set ::accepted 0
set ::blocked 0
set ::lasthealth 8
file mkdir $::env(MISSION_TEST_OUT)
set ::timing [open "$::env(MISSION_TEST_OUT)/timing.txt" w]
proc word {addr value} {poke $addr [expr {$value&255}];poke [expr {$addr+1}] [expr {$value>>8}]}
proc expect {addr value message} {if {[peek $addr]!=$value} {error "$message at $::n: [format %04x $addr]=[peek $addr], expected $value"}}
proc sample {} {
 for {set row 0} {$row<11} {incr row} {keymatrixup $row 255}
 if {$::n<0} {
  if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {debug cont;return}
  set ::n 0
  foreach addr {0xc851 0xc871 0xc891 0xc8c1 0xc8e1 0xc911 0xc921 0xc941 0xc951 0xc961 0xc971} {poke $addr 5}
  foreach addr {0xc8a2 0xca02 0xc8ed 0xc8dd 0xc8d4 0xc823 0xc857 0xc820 0xc803 0xc804 0xc80a 0xc981} {poke $addr 0}
  poke 0xc8da 1;poke 0xc8d0 1;poke 0xc930 1;poke 0xc8e0 1;poke 0xc8e9 5;poke 0xc900 1;poke 0xc990 49
  word 0xc972 400;poke 0xc97f 8
  word 0xc840 109;poke 0xc801 96
  word 0xc75c 0;poke 0xc75e 0
 } else {incr ::n}
 puts $::timing "$::n [machine_info time]"
 switch $::n {
  1 {expect 0xc986 8 "boss initial health";expect 0xc981 1 "boss activation";poke 0xc803 12;poke 0xc809 1}
  2 {expect 0xc986 8 "remote kick hit boss";word 0xc982 181;poke 0xc803 12;poke 0xc809 0}
  3 {expect 0xc986 8 "wrong-facing kick hit boss";poke 0xc803 0;poke 0xc981 2;poke 0xc989 0;poke 0xc984 36;poke 0xc988 0}
  4 {expect 0xc856 8 "windup damaged player";poke 0xc984 24}
  5 {expect 0xc856 7 "boss should take one player health"}
  6 {expect 0xc856 7 "one attack counted twice";poke 0xc857 0;poke 0xc823 0;poke 0xc80a 35;poke 0xc804 20;poke 0xc984 24}
  7 {expect 0xc856 7 "boss hit high jump";poke 0xc981 1;poke 0xc803 0;poke 0xc804 0;poke 0xc80a 0;poke 0xc856 8}
 }
 # A new kick every 80 frames, with actual release and recovery between them.
 if {$::n>=20 && $::n<901 && ($::n-20)%80==0} {
  if {[peek 0xc986]>0} {
   poke 0xc981 1;word 0xc982 181;poke 0xc801 96
   poke 0xc803 12;poke 0xc809 1;poke 0xc823 0;poke 0xc857 0;poke 0xc856 8
  }
 }
 if {$::n>=21 && $::n<902 && ($::n-21)%80==0} {
  set hp [peek 0xc986]
  if {$hp<$::lasthealth} {incr ::accepted;set ::lasthealth $hp} elseif {[peek 0xc981]==6} {incr ::blocked}
 }
 if {$::n>=22 && ($::n-22)%80==0} {poke 0xc803 0}
 # Stay invulnerable between the deliberately tested player-damage contacts.
 if {$::n>7} {poke 0xc857 100;poke 0xc823 0;poke 0xc856 8}
 if {$::n in {10 24 104 264 344 504 584 744 824}} {
  foreach {name device start size} {vram "Sunrise GFX9000 VRAM" 0 524288 regs "Sunrise GFX9000 regs" 0 64 ram memory 0xc800 2048} {
   set f [open "$::env(MISSION_TEST_OUT)/hud-$::n-$name.bin" wb];puts -nonewline $f [debug read_block $device $start $size];close $f
  }
 }
 if {$::n in {40 340 880}} {screenshot "$::env(MISSION_TEST_OUT)/boss-$::n.png"}
 if {$::n==940} {
  expect 0xc986 0 "boss not defeated";expect 0xc981 5 "boss stood up again";expect 0xc98f 10 "wrong down pose"
  if {$::accepted!=8 || $::blocked<2} {error "hits=$::accepted blocks=$::blocked"}
 }
 if {$::n>=942 && $::n<1008} {
  set index [expr {($::n-942)/3}]
  if {($::n-942)%3==0} {
   poke 0xc98f [expr {$index%11}];poke 0xc988 [expr {$index/11}]
   word 0xc982 200;poke 0xc801 190;poke 0xc803 0;poke 0xc823 0;poke 0xc804 0;poke 0xc80a 0
  }
  if {($::n-942)%3==2} {
   foreach {name device start size} {vram "Sunrise GFX9000 VRAM" 0 524288 regs "Sunrise GFX9000 regs" 0 64 ram memory 0xc800 2048} {
    set f [open "$::env(MISSION_TEST_OUT)/$index-$name.bin" wb];puts -nonewline $f [debug read_block $device $start $size];close $f
   }
  }
 }
 if {$::n==1010} {
  close $::timing
  set f [open "$::env(MISSION_TEST_OUT)/result.txt" w];puts $f "OK: 8 accepted hits, $::blocked blocks, range, facing, active attack, one damage per attack, high jump and permanent defeat";close $f
  exit;return
 }
 debug cont
}
proc safe_sample {} {if {[catch {sample} message]} {puts stderr "FAIL: $message";exit 1}}
debug set_bp $::env(MISSION_LOOP) {} safe_sample
after time 45 {exit 1}
