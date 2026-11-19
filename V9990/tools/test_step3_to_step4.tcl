set throttle off
set ::out $::env(STEP3_TO_STEP4_OUT)
file mkdir $::out
set ::seen8 0; set ::seen9 0;set ::seen9_other 0; set ::seen10 0;set ::seen_map_other 0;set ::sent 0;set ::map_pending 0
proc capture {name} {
 foreach {file device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64 pal "Sunrise GFX9000 palette" 256} {
  set f [open "$::out/$name-$file.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
 set ::videosource GFX9000
 screenshot -raw "$::out/$name.png"
}
after time 12 {
 poke 0xc0df 8;poke 0xc0de 0;poke 0xc0d5 1;poke 0xc095 0
}
proc drive {} {
 set stage [peek 0xc418]
 if {$stage==4 && !$::sent} {
  poke 0xc414 160;poke 0xc415 15
  poke 0xc434 52;poke 0xc435 1
  set previous [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc0dd]-2)&65535}]
  poke 0xc436 [expr {$previous&255}];poke 0xc437 [expr {$previous>>8}]
  set ::sent 1
 }
 if {$stage==7 && $::sent==1} {
  set ::sent 2
  after time 2 {
   set ::pre_score [expr {[peek 0xc75c]+256*[peek 0xc75d]+65536*[peek 0xc75e]}]
   poke 0xc731 $::env(STEP3_REMAINING);poke 0xc735 0;poke 0xc72f 0;poke 0xc72e 0
   set now [expr {[peek 0xfc9e]+256*[peek 0xfc9f]}]
   poke 0xc732 [expr {$now&255}];poke 0xc733 [expr {$now>>8}]
   poke 0xc700 0;poke 0xc701 13
  }
 }
 if {$stage==8 && !$::seen8} {
  set ::seen8 1
  set ::race_points [expr {[peek 0xc739]+256*[peek 0xc73a]}]
  after time 0.2 {capture bonus}
 }
 ;# the cadets' scene: arcade frames in C760h (src/step3_transition.asm)
 if {$stage==9 && !$::seen9 && [peek16 0xc760]>100} {set ::seen9 1;capture animation}
 if {$stage==9 && !$::seen9_other && [peek16 0xc760]>300} {set ::seen9_other 1;capture animation-other}
 if {$stage==10 && !$::map_pending} {
  set ::map_pending 1
  after time 0.2 {
   binary scan [debug read_block "Sunrise GFX9000 regs" 18 1] cu ::map_page
   capture map
   set ::seen10 1
  }
 }
 if {$stage==10 && $::seen10 && !$::seen_map_other} {
  binary scan [debug read_block "Sunrise GFX9000 regs" 18 1] cu page
  if {($page&1)!=($::map_page&1)} {
   set ::seen_map_other 1
   after time 0.08 {capture map-other}
  }
 }
 if {$stage==11 && $::seen8 && $::seen9 && $::seen9_other && $::seen10 && $::seen_map_other} {
  set ::score [expr {[peek 0xc75c]+256*[peek 0xc75d]+65536*[peek 0xc75e]}]
  set ::bonus [peek 0xc736];set ::seconds [peek 0xc806]
  after time 1 {
   set ::before [peek 0xc800];keymatrixdown 8 128
   after time 0.3 {
    keymatrixup 8 128
    capture step4
    set ::after_move [peek 0xc800]
    if {$::env(STEP4_FULL_TEST) eq "1"} {
     keymatrixdown 8 1
     after time 0.3 {
      set ::shots [peek 0xc803]
      for {set i 0} {$i<7} {incr i} {incr ::shots [peek [expr {0xca02+3*$i}]]}
      keymatrixup 8 1
      watch_step4_bank
     }
    } else {
     set ::shots -1;set ::bank -1;set ::bank_stage -1
     finish_test
    }
   }
  }
  return
 }
 if {[machine_info time]>160} {exit 1}   ;# bonus screens last as long as their music
 after frame drive
}
proc watch_step4_bank {} {
 set tick [expr {[peek 0xc8e4]+256*[peek 0xc8e5]}]
 if {$tick>=1100 && [peek 0xc8f3]==0} {
  set ::bank [peek 0xc8e8];set ::bank_stage [peek 0xc418]
  finish_test
  return
 }
 if {[machine_info time]>155} {exit 1}
 after frame watch_step4_bank
}
proc finish_test {} {
 set f [open "$::out/result.txt" w]
 puts $f "$::seen8 $::seen9 $::seen10 $::seen_map_other [peek 0xc418] $::bonus $::seconds $::score $::before $::after_move $::pre_score $::race_points $::shots $::bank $::bank_stage"
 close $f;exit
}
after time 12.1 drive
after time 170 {exit 1}   ;# bonus screens last as long as their music
