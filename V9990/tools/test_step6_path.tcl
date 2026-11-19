set throttle off
set ::out $::env(STEP3_TO_STEP4_OUT)
file mkdir $::out
set ::step5_seen 0;set ::step5_result 0;set ::step5_map 0;set ::pressed 0;set ::start_score 0
set ::step4_done 0;set ::step4_bonus 0;set ::step4_map 0;set ::page_seen -1
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
 if {$stage==9 && !$::seen9 && [peek 0xc76a]>25} {set ::seen9 1;capture animation}
 if {$stage==9 && !$::seen9_other && [peek 0xc76a]>65} {set ::seen9_other 1;capture animation-other}
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
 if {$stage==11 && !$::step4_done} {
  set ::step4_done 1
  set ::initial_score [expr {[peek 0xc75c]+256*[peek 0xc75d]+65536*[peek 0xc75e]}]
  poke 0xc809 $::env(STEP4_HITS)
  poke 0xc806 1
  set previous [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc81c]-2)&65535}]
  poke 0xc81a [expr {$previous&255}];poke 0xc81b [expr {$previous>>8}]
 }
 if {$stage==12 && !$::step4_bonus} {set ::step4_bonus 1; after time 0.3 {capture bonus4}}
 if {$stage==13 && !$::step4_map} {set ::step4_map 1}
 if {$stage==14 && !$::step5_seen} {
  set ::step5_seen 1
  set ::start_score [expr {[peek 0xc75c]+256*[peek 0xc75d]+65536*[peek 0xc75e]}]
  set ::start_seconds [peek 0xc887]
  after time 0.4 {capture front5}
  if {$::env(STEP5_WIN) eq "1"} {tap5}
 }
 if {$stage==15 && !$::step5_result} {set ::step5_result 1;keymatrixup 8 1;after time 1.2 {capture result5}}
 if {$stage==16 && !$::step5_map} {
  set ::step5_map 1
  set ::before_page [peek 0xc0b6]
  after time 0.2 {
   capture map5
   binary scan [debug read_block "Sunrise GFX9000 regs" 18 1] cu ::map5_page
   after frame wait_map5
  }
 }
 if {[machine_info time]>160} {exit 1}
 after frame drive
}
proc wait_map5 {} {
 binary scan [debug read_block "Sunrise GFX9000 regs" 18 1] cu page
 if {($page&1)==($::map5_page&1)} {after frame wait_map5;return}
 capture map5-other
 set f [open "$::out/step5-result.txt" w]
 set score [expr {[peek 0xc75c]+256*[peek 0xc75d]+65536*[peek 0xc75e]}]
 puts $f "$::step4_map $::step5_seen $::step5_result [peek 0xc88c] [peek 0xc736] [expr {$score-$::start_score}] $::start_seconds [peek 0xc418] [expr {[peek 0xc895]+256*[peek 0xc896]}] [peek 0xc897]"
 close $f
 after frame watch_step6
}
proc watch_step6 {} {
 if {[peek 0xc418]==17} {
  set f [open "$::out/step6-start.txt" w]
  puts $f "[peek 0xc418] [peek 0xc45b] [peek 0xc435] [peek 0xc432] [peek 0xc45d]"
  close $f;exit
 }
 if {[machine_info time]>160} {exit 1}
 after frame watch_step6
}
proc tap5 {} {
 if {[peek 0xc418]!=14} {keymatrixup 8 1;return}
 if {[peek 0xc880]==1} {
  if {$::pressed} {keymatrixup 8 1;set ::pressed 0} else {keymatrixdown 8 1;set ::pressed 1}
 }
 after time 0.03 tap5
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
