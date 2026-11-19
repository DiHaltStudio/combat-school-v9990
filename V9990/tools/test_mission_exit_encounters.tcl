set throttle off
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 poke 0xc840 24;poke 0xc841 2;poke 0xc900 1;poke 0xc941 5;poke 0xc990 1
 after time 0.3 {
  if {[peek 0xc951]!=1 || [peek 0xc961]!=1 || [peek 0xc941]!=5 || [peek 0xc96d]!=80} {error "door spawn or survivor failed"}
  poke 0xc951 5;poke 0xc961 5
  poke 0xc840 40;poke 0xc841 1
  after time 0.3 {
   if {[peek 0xc951]!=5 || [peek 0xc961]!=5 || [peek 0xc971]!=1 || [peek 0xc941]!=5} {error "respawn or room encounter failed"}
   set f [open $::env(MISSION_EXIT_RESULT) w]
   puts $f "OK: doorway pair and room attacker; defeated actors stay defeated"
   close $f
   exit
  }
 }
}
after time 10 {after frame ready}
after time 20 {exit 1}
