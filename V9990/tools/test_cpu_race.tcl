set throttle off
set ::race_log [open $::env(RACE_LOG) w]
proc cpu_sample {} {
 set t [machine_info time]
 if {$t>=10} {
  set page [expr {0xc100+256*([debug read "Sunrise GFX9000 regs" 18]&1)}]
  puts $::race_log "[format %.3f $t] [peek 0xc090] [peek 0xc091] [peek 0xc094] [peek 0xc0c4] [peek 0xc095] [peek 0xc0d0] [peek 0xc0d9] [peek 0xc0c5] [peek [expr {$page+0xa0}]]"
 }
 if {$t>=100} {close $::race_log; exit}   ;# GAME OVER and the RANKING come first
 after time 0.1 cpu_sample
}
after time 10 cpu_sample
