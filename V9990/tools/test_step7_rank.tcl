set throttle off
set out $::env(STEP7_RANK_OUT)
file mkdir $out
proc watch_rank {} {
 if {[peek 0xc82a]==4} {
  after time 0.12 {
   set f [open "$::out/rank.txt" w];puts $f "[peek 0xc834] [peek 0xc75c] [peek 0xc75d] [peek 0xc75e]";close $f
   foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
    set f [open "$::out/$part.bin" w];fconfigure $f -translation binary
    puts -nonewline $f [debug read_block $device 0 $size];close $f
   }
   exit
  }
  return
 }
 after frame watch_rank
}
after time 10 {
 set n $::env(STEP7_SCORE)
 poke 0xc75c [expr {$n&255}];poke 0xc75d [expr {($n>>8)&255}];poke 0xc75e [expr {($n>>16)&255}]
 poke 0xc829 4;poke 0xc814 1;poke 0xc828 179
 after frame watch_rank
}
after time 45 {exit 1}   ;# the ceremony comes first (about 30 s in)
