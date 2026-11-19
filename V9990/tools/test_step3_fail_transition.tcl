set throttle off
set ::sent 0
proc watch {} {
 set stage [peek 0xc418]
 if {$stage==4 && !$::sent} {
  poke 0xc434 52;poke 0xc435 1
  set previous [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc0dd]-2)&65535}]
  poke 0xc436 [expr {$previous&255}];poke 0xc437 [expr {$previous>>8}]
  set ::sent 1
 }
 if {$stage==7 && $::sent==1} {
  set ::sent 2
  after time 2 {
   poke 0xc701 0;poke 0xc72f 0;poke 0xc735 0;poke 0xc731 1
   set previous [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc734]-2)&65535}]
   poke 0xc732 [expr {$previous&255}];poke 0xc733 [expr {$previous>>8}]
   after time 4 {
    set f [open $::env(STEP3_FAIL_RESULT) w]
    puts $f "[peek 0xc418] [peek 0xc735] [peek 0xc72e] [peek 0xc731]"
    close $f;exit
   }
  }
 }
 if {[machine_info time]>80} {exit 1}
 after frame watch
}
after time 12 {poke 0xc0df 8;poke 0xc0de 0;poke 0xc0d5 1;poke 0xc095 0}
after time 12.1 watch
