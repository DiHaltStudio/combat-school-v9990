set ::result_scenario $::env(RESULT_TEST)
after time 12 {
 if {$::result_scenario eq "player"} {
  poke 0xc000 100
  poke 0xc006 184
  poke 0xc00c 9
  poke 0xc008 48
  poke 0xc00b 60
 } elseif {$::result_scenario eq "cpu"} {
  poke 0xc090 184
  poke 0xc091 9
  poke 0xc092 100
  after time 1 {
   poke 0xc000 100
   poke 0xc006 184
   poke 0xc00c 9
   poke 0xc008 48
   poke 0xc00b 60
  }
 } elseif {$::result_scenario eq "timeout"} {
  poke 0xc0d0 1
 }
}
