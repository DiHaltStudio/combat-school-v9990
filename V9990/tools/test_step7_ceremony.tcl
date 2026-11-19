# Graduation ceremony (src/step7_ceremony.asm): win against the instructor,
# then log every display frame of the ceremony (frame counter C900, SCAY)
# and take screenshots with the arms raised, while rising, at the flag and
# while the flag waves. Ends at the rank screen.
set throttle off
catch {set vsync off}
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
set ::log [open "$out/ceremony.txt" w]
set ::shots {0 60 150 240 300}
set ::waving 0
proc shot {name} {set ::videosource GFX9000;screenshot -raw "$::out/ceremony-$name.png"}
proc watch_ending {} {
 set stage [peek 0xc82a]
 if {$stage==3} {
  set f [expr {[peek 0xc900]+256*[peek 0xc901]}]
  set scay [expr {[debug read "Sunrise GFX9000 regs" 17]+256*([debug read "Sunrise GFX9000 regs" 18]&31)}]
  puts $::log "[machine_info time] $f $scay"
  if {[llength $::shots] && $f>=[lindex $::shots 0]} {
   if {$f>0 || [peek 0xc902]==0} {shot [lindex $::shots 0];set ::shots [lrange $::shots 1 end]}
  }
  if {$scay>=2816 && !$::waving} {
   set ::waving 1;after time 0.5 {shot waving}
   set f [open "$::out/vram.bin" wb];puts -nonewline $f [debug read_block "Sunrise GFX9000 VRAM" 0 524288];close $f
  }
 }
 if {$stage==4} {
  after time 0.3 {shot rank;close $::log;exit}
  return
 }
 after frame watch_ending
}
after time 10 {
 poke 0xc75c 242;poke 0xc75d 9;poke 0xc75e 4;poke 0xc829 15
 poke 0xc800 0;poke 0xc801 70;poke 0xc809 0;poke 0xc813 100
 poke 0xc80c 1;poke 0xc80d 0;poke 0xc80e 100;poke 0xc810 0
 poke 0xc803 0;poke 0xc805 0;poke 0xc814 0;poke 0xc822 0;poke 0xc826 0;poke 0xc827 0
 keymatrixdown 8 1
 after time 0.15 {keymatrixup 8 1}
 after frame watch_ending
}
after time 90 {exit 1}
