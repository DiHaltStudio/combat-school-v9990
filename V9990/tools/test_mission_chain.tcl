set throttle off
set ::n -1
file mkdir $::env(MISSION_TEST_OUT)
set ::timing [open "$::env(MISSION_TEST_OUT)/timing.txt" w]
proc word {addr value} {poke $addr [expr {$value&255}];poke [expr {$addr+1}] [expr {$value>>8}]}
proc expect {addr value message} {if {[peek $addr]!=$value} {error "$message: [format %04x $addr]=[peek $addr], expected $value at $::n"}}
proc sample {} {
 for {set row 0} {$row<11} {incr row} {keymatrixup $row 255}
 if {$::n<0} {
  if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {debug cont;return}
  set ::n 0
  foreach addr {0xc851 0xc871 0xc891 0xc8c1 0xc8e1 0xc911 0xc921 0xc941 0xc951 0xc961} {poke $addr 5}
  foreach addr {0xc8a2 0xca02 0xc8ed 0xc8dd 0xc8d4 0xc823 0xc857 0xc820 0xc803 0xc804 0xc80a} {poke $addr 0}
  poke 0xc8da 1;poke 0xc8d0 1;poke 0xc930 1;poke 0xc8e0 1;poke 0xc8e9 5;poke 0xc900 1;poke 0xc990 49
  word 0xc840 200;poke 0xc801 96
  poke 0xc971 1;word 0xc972 196;poke 0xc97e 0;poke 0xc97a 0;poke 0xc97b 0;poke 0xc97c 0;poke 0xc977 0
  word 0xc75c 0;poke 0xc75e 0
 } else {incr ::n}
 puts $::timing "$::n [machine_info time]"
 switch $::n {
  0 {poke 0xc803 12;poke 0xc809 1}
  1 {expect 0xc97e 0 "distant kick hit";word 0xc972 272;poke 0xc803 12;poke 0xc809 0}
  2 {expect 0xc97e 0 "backwards kick hit";poke 0xc803 12;poke 0xc809 1}
  3 {expect 0xc97e 1 "first hit";expect 0xc971 3 "hurt state"}
  32 {expect 0xc97e 1 "held kick counted twice";poke 0xc803 0}
  33 {word 0xc972 272;poke 0xc803 12;poke 0xc809 1}
  34 {expect 0xc97e 2 "second hit";expect 0xc971 3 "second hit must not kill"}
  61 {poke 0xc803 0}
  62 {word 0xc972 272;poke 0xc803 12;poke 0xc809 1}
  63 {expect 0xc97e 3 "third hit";expect 0xc971 4 "fall state"}
  130 {
   expect 0xc971 5 "enemy did not remain down"
   if {[peek 0xc75c]+256*[peek 0xc75d]!=1500} {error "wrong score"}
   poke 0xc971 2;word 0xc972 246;poke 0xc978 0;poke 0xc974 34;poke 0xc803 0;poke 0xc97a 0
  }
  131 {expect 0xc856 8 "windup damaged player";poke 0xc974 27;poke 0xc80a 40}
  132 {expect 0xc856 8 "chain reached high jump";poke 0xc80a 0;poke 0xc8dd 1;poke 0xc974 27}
  133 {expect 0xc856 8 "chain reached pipe";poke 0xc8dd 0;poke 0xc974 27;word 0xc972 346}
  134 {expect 0xc856 8 "chain hit behind attacker";word 0xc972 246;poke 0xc974 27}
  135 {expect 0xc856 0 "extended chain failed to hit";poke 0xc856 8;poke 0xc823 0;poke 0xc857 0;poke 0xc971 5}
 }
 if {$::n>=3 && $::n<32} {poke 0xc803 12}
 # Freeze physics through a separate tick breakpoint during visual cases.
 if {$::n>=140 && $::n<212} {
  set index [expr {($::n-140)/3}]
  if {($::n-140)%3==0} {
   set pose [expr {$index%9}];set facing [expr {($index/9)%2}]
   set pos 220
   if {$index>=18} {set pos [lindex {158 186 440 460 200 400} [expr {$index-18}]]}
   poke 0xc971 5;poke 0xc97f $pose;poke 0xc978 $facing;word 0xc972 $pos
   poke 0xc803 0;poke 0xc823 0;poke 0xc820 0;poke 0xc8dd 0;poke 0xc804 0;poke 0xc80a 0
  }
  if {($::n-140)%3==2} {
   foreach {name device start size} {vram "Sunrise GFX9000 VRAM" 0 524288 regs "Sunrise GFX9000 regs" 0 64 ram memory 0xc800 2048} {
    set f [open "$::env(MISSION_TEST_OUT)/$index-$name.bin" wb];puts -nonewline $f [debug read_block $device $start $size];close $f
   }
   if {$index in {4 13 18 20}} {screenshot "$::env(MISSION_TEST_OUT)/pose-$index.png"}
  }
 }
 if {$::n==212} {
  foreach addr {0xc951 0xc961 0xc971} {poke $addr 1}
  word 0xc952 230;word 0xc962 360;word 0xc972 270
  poke 0xc97e 0;poke 0xc97a 0;poke 0xc803 0;poke 0xc8dd 1
  poke 0xc856 8;poke 0xc823 0;poke 0xc857 0
 }
 if {$::n>212 && $::n<290} {poke 0xc801 95;poke 0xc8dd 1}
 if {$::n==350} {
  foreach addr {0xc951 0xc961} {poke $addr 5}
  # Independent approach fixture; this camera teleport rebuilds both pages.
  # The camera stays at 258 while the chain assailant is up (arcade lock),
  # so the player walks on the screen instead.
  word 0xc840 258;set ::chain_origin 294
  poke 0xc801 96;word 0xc972 $::chain_origin
  poke 0xc971 2;poke 0xc974 1;poke 0xc97e 0;poke 0xc97a 0
  poke 0xc8dd 0;poke 0xc803 0;poke 0xc823 0;poke 0xc857 0;poke 0xc856 8
 }
 if {$::n==351} {expect 0xc977 48 "missing pause"}
 if {$::n>351 && $::n<385} {
  expect 0xc971 1 "chain attacked during pause"
  expect 0xc856 8 "player hurt during pause"
  if {[peek 0xc972]+256*[peek 0xc973]!=$::chain_origin} {error "chain moved during pause"}
  poke 0xc801 [expr {[peek 0xc801]-1}]
 }
 if {$::n==385} {poke 0xc803 12;poke 0xc809 1}
 if {$::n==386} {expect 0xc97e 1 "cannot approach and hit during pause";expect 0xc856 8 "approaching player died"}
 if {$::n==400} {
  close $::timing
  set f [open "$::env(MISSION_TEST_OUT)/result.txt" w];puts $f "OK: range, facing, three distinct hits, score, death, active chain, jump and pipe immunity; loaded room scroll and safe approach during post-strike pause";close $f
  exit;return
 }
 debug cont
}
proc safe_sample {} {
 if {[catch {sample} message]} {
  puts stderr "FAIL: $message, player=[peek 0xc801] attack=[peek 0xc803] jump=[peek 0xc804] height=[peek 0xc80a] direction=[peek 0xc809] hang=[peek 0xc8dd] crate=[peek 0xc8d4] distance=[peek 0xc9b2] health=[peek 0xc856] camera=[peek 0xc840],[peek 0xc841] enemy=[peek 0xc972],[peek 0xc973]"
  exit 1
 }
}
debug set_bp $::env(MISSION_LOOP) {} safe_sample
after time 30 {exit 1}
