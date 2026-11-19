# Bars entry (Step 1): running into the front post without jumping must not
# get past it; BARS_JUMP=1 jumps at the post, grabs the bars and crosses them.
proc pulse {n} {
 if {$n<=0} return
 keymatrixdown 8 1
 after time 0.04 "keymatrixup 8 1; after time 0.06 {pulse [expr {$n-1}]}"
}
after time 12 {
 # Runner centre at world 1980, 52 pixels before the post.
 poke 0xc000 100
 poke 0xc006 72
 poke 0xc00c 7
 pulse 120
 if {[info exists ::env(BARS_JUMP)]} {
  after time 3 {keymatrixdown 4 4; after time 0.12 {keymatrixup 4 4}}
 }
}
