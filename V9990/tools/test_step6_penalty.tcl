set throttle off
set ::out $::env(STEP6_OUT)
file mkdir $::out
set ::blocked 0
set ::released 0
set ::start_tick 0
proc ticks {} {expr {[peek 0xfc9e]+256*[peek 0xfc9f]}}
proc sample_penalty {} {
 if {[peek 0xc45e] && !$::blocked} {
  set ::blocked 1;set ::start_tick [ticks]
 }
 if {$::blocked && !$::released && ![peek 0xc45e]} {
  set ::released 1;set ::duration [expr {([ticks]-$::start_tick)&65535}]
  set ::end_seed [peek 0xc449]
 }
 if {!$::released} {after time 0.02 sample_penalty}
}
after time 10 {poke 0xc736 0;poke 0xc734 50;reg PC 0x400a}
after time 11 {
 set ::stage [peek 0xc418]
 poke 0xc432 31;poke 0xc45d 2;poke 0xc434 0;poke 0xc449 93
 foreach addr {0xc44a 0xc44b 0xc44c 0xc44d 0xc44e} x {40 64 88 112 136} {poke $addr $x}
 poke 0xc43b 50;poke 0xc430 4;poke 0xc431 50;poke 0xc433 0
 set now [ticks]
 set past [expr {($now-$::env(STEP6_WAVE_ELAPSED)*[peek 0xc0dd])&65535}]
 poke 0xc450 [expr {$past&255}];poke 0xc451 [expr {$past>>8}]
 set ::start_time [peek 0xc435]
 # The sight stays on the row of boards: a shot left of them must miss.
 keymatrixdown 8 1
}
after time 11.12 {keymatrixup 8 1}
after time 11.25 {
 set ::miss_penalty [peek 0xc45e];set ::miss_hits [peek 0xc434]
 poke 0xc430 64;poke 0xc431 50;poke 0xc433 0
 keymatrixdown 8 1
 after time 0.02 sample_penalty
}
after time 11.40 {keymatrixup 8 1;keymatrixdown 8 128;after time 0.05 {keymatrixdown 8 1}}
after time 11.70 {
 set ::locked [peek 0xc45e];set ::locked_x [peek 0xc430]
 set ::locked_y [peek 0xc431];set ::locked_hits [peek 0xc434]
 set ::locked_mask [peek 0xc432];keymatrixup 8 128;keymatrixup 8 1
}
after time 14.6 {
 set ::after_penalty [peek 0xc45e];set ::end_time [peek 0xc435]
 set ::before_move [peek 0xc430];keymatrixdown 8 128
}
after time 14.9 {
 keymatrixup 8 128
 set f [open "$::out/result.txt" w]
 puts $f "$::stage $::miss_penalty $::miss_hits $::blocked $::locked $::locked_x $::locked_y $::locked_hits $::locked_mask $::released $::duration $::end_seed $::start_time $::end_time $::after_penalty $::before_move [peek 0xc430] [peek 0xc0dd]"
 close $f;exit
}
after time 20 {exit 1}
