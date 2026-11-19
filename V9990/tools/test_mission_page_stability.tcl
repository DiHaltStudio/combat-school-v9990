set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
set ::sample 0
set ::close [expr {[info exists ::env(MISSION_PAGE_CLOSE)] && $::env(MISSION_PAGE_CLOSE) eq "1"}]
proc capture {} {
 incr ::sample
 if {$::close} {
  # Keep both opponents close while preventing contact damage; attacks and
  # hit flashes still run through the real rendering and collision code.
  poke 0xc851 1;poke 0xc852 240;poke 0xc853 4
  poke 0xc871 1;poke 0xc872 48;poke 0xc873 5
  poke 0xc857 255
 }
 if {$::sample%18==1} {keymatrixdown 8 1}
 if {$::sample%18==3} {keymatrixup 8 1}
 if {$::sample > 4} {
  set n [expr {$::sample-5}]
  foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
   set f [open [format "%s/%02d-%s.bin" $::out $n $part] w]
   fconfigure $f -translation binary
   puts -nonewline $f [debug read_block $device 0 $size]
   close $f
  }
  set ::videosource GFX9000
  screenshot -raw [format "%s/%02d.png" $::out $n]
 }
 if {$::sample>=44} {exit}
 after frame capture
}
after time 10 {
 poke 0xc840 176;poke 0xc841 4;poke 0xc800 0;poke 0xc801 96
 poke 0xc809 0;poke 0xc803 0;poke 0xc804 0;poke 0xc823 0;poke 0xc856 8
 poke 0xc851 4;poke 0xc852 192;poke 0xc853 4;poke 0xc854 250
 poke 0xc871 4;poke 0xc872 96;poke 0xc873 5;poke 0xc874 250
 poke 0xc891 5;poke 0xc8c1 5;poke 0xc8d0 1;poke 0xc8da 1;poke 0xc8ad 8;poke 0xc8a2 0
 if {[info exists ::env(MISSION_PAGE_FIRE)] && $::env(MISSION_PAGE_FIRE) eq "1"} {
  poke 0xc8a0 96;poke 0xc8a1 5;poke 0xc8b2 160;poke 0xc8b5 255;poke 0xc8d5 2;poke 0xc8a2 2
 }
 after frame capture
}
after time 30 {exit 1}
