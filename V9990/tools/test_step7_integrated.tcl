set throttle off
set out $::env(STEP7_INTEGRATED_OUT)
file mkdir $out
set ::bonus 0; set ::interlude 0; set ::map 0; set ::combat 0
set ::win 0; set ::ending_map 0; set ::ceremony 0; set ::flag 0
after time 10 {
 set n 260001
 poke 0xc75c [expr {$n&255}]; poke 0xc75d [expr {($n>>8)&255}]; poke 0xc75e [expr {($n>>16)&255}]
 poke 0xc736 0; poke 0xc734 50; reg PC 0x400a
}
after time 11 {
 poke 0xc434 37; poke 0xc435 1
 set prev [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc0dd]-2)&65535}]
 poke 0xc436 [expr {$prev&255}]; poke 0xc437 [expr {$prev>>8}]
}
proc watch {} {
 set stage [peek 0xc418]
 if {$stage==19} {set ::bonus 1}
 if {$stage==20} {set ::interlude 1}
 if {$stage==18} {set ::map 1}
 if {$stage==21 && !$::combat} {
  set ::combat 1
  after time 1 {
   set ::score_before [expr {[peek 0xc75c]+256*[peek 0xc75d]+65536*[peek 0xc75e]}]
   set f [open "$::out/combat-vram.bin" w]; fconfigure $f -translation binary
   puts -nonewline $f [debug read_block "Sunrise GFX9000 VRAM" 0 524288]; close $f
   poke 0xc829 8; poke 0xc814 1; poke 0xc828 179
  }
 }
 if {$::combat && [peek 0xc814]==1} {set ::win 1}
 if {$::combat} {
  switch [peek 0xc82a] {
   1 {set ::ending_map 1}
   2 {set ::ceremony 1}
   3 {set ::flag 1}
   4 {
    after time 0.15 {
     foreach {part device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
      set f [open "$::out/$part.bin" w]; fconfigure $f -translation binary
      puts -nonewline $f [debug read_block $device 0 $size]; close $f
     }
     set f [open "$::out/rank.txt" w]
     puts $f "[peek 0xc834] [peek 0xc75c] [peek 0xc75d] [peek 0xc75e]"; close $f
     set f [open "$::out/path.txt" w]
     puts $f "$::bonus $::interlude $::map $::combat $::win $::ending_map $::ceremony $::flag $::score_before"; close $f
     exit
    }
    return
   }
  }
 }
 if {[machine_info time]>60} {exit 1}
 after frame watch
}
after time 11.1 watch
after time 65 {exit 1}
