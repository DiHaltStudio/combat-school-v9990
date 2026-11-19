# Arcade rules (tools/mame_step7_rules.lua): READY with the clock stopped at
# 1:00.0, a crouching player only receives high kicks and dodges them, the
# instructor mixes punches, kicks and sweeps against a standing player, and
# the player loses when the clock runs out (TIME UP).
set throttle off
set out $::env(STEP7_VISUAL_OUT)
file mkdir $out
set ::types {}
set ::prev 0
proc watch {} {
 set a [peek 0xc80d]
 if {$a>$::prev} {lappend ::types [peek 0xc842]}
 set ::prev $a
 if {[peek 0xc80b]<3} {poke 0xc80b 8}
 if {[peek 0xc80c]<3} {poke 0xc80c 8}
 after frame watch
}
after time 7.5 {set ::ready [peek 0xc849];set ::start [peek 0xc844].[peek 0xc845];watch;keymatrixdown 8 64}
after time 30 {set ::crouch_types $::types;set ::crouch_hp [peek 0xc80b];keymatrixup 8 64;set ::types {}}
after time 55 {set ::stand_types $::types;poke 0xc844 0;poke 0xc845 2}
after time 56 {
 set f [open "$out/rules.txt" w]
 puts $f "$::ready $::start $::crouch_hp [lsort -unique $::crouch_types] | [lsort -unique $::stand_types] | [peek 0xc814] [peek 0xc843]"
 close $f;exit
}
after time 60 {exit 1}
