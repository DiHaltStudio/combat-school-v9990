set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set f [open $::env(MISSION_STATE) rb];set ::fixture [read $f];close $f
set ::n -1
set ::cameras {1706 1506 1296 1056 706 511 512 767 768 1023 1024 1279 1280 1535 1536 1791 1792 109 128 147 256 300 170 176 177 180}
set ::log [open "$out/timing.txt" w]
proc sample {} {
 keymatrixup 4 4
 if {$::n<0} {
  if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {debug cont;return}
  debug write_block memory 0xc800 $::fixture
  poke 0xca26 0;poke 0xca27 0;poke 0xca20 0;poke 0xca21 0
  keymatrixdown 8 16
  set ::n 0
 } else {
  incr ::n
  puts $::log "$::n [machine_info time] [expr {[peek 0xc840]+256*[peek 0xc841]}] [peek 0xc8dd]"
  if {$::n in {10 80 160 240 320 400 480 600} || ($::n>600 && $::n%10==0)} {
   foreach {name device start size} {vram "Sunrise GFX9000 VRAM" 0 524288 regs "Sunrise GFX9000 regs" 0 64 ram memory 0xc800 2048} {
    set f [open "$::out/$::n-$name.bin" wb];puts -nonewline $f [debug read_block $device $start $size];close $f
   }
  }
  if {$::n==240} {keymatrixup 8 16;keymatrixdown 8 128}
  if {$::n==160} {screenshot "$::out/scroll.png"}
  if {$::n==480} {keymatrixup 8 128}
  if {$::n==600} {screenshot "$::out/stationary.png"}
  if {$::n>=600 && $::n%10==0} {
   if {($::n>600 && $::n<=650) || $::n==780} {screenshot "$::out/seam-$::n.png"}
   set index [expr {($::n-600)/10}]
   if {$index==[llength $::cameras]} {close $::log;exit;return}
   set cam [lindex $::cameras $index]
   poke 0xc840 [expr {$cam&255}];poke 0xc841 [expr {$cam>>8}]
   poke 0xc801 96;poke 0xc8dd 1
  }
 }
 debug cont
}
debug set_bp $::env(MISSION_LOOP) {} sample
after time 40 {exit 1}
