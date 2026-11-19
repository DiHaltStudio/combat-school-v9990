# make test-psg-music: each song of the PSG driver (build/psg/test.rom,
# Spectrum periods) for as many ticks as its Spectrum capture; R0-R13 after
# every tick to $PSG_OUT/songNN.txt (tools/check_psg_music.py compares).
set throttle off
set out $::env(PSG_OUT)
file mkdir $out
set ::done [expr {$::env(PSG_DONE)}]
set ::ticks [split $::env(PSG_TICKS) ,]
set ::song -1
set ::left 0
proc tick {} {
 if {$::song<0 || $::left<=0} return
 set regs {}
 for {set r 0} {$r<14} {incr r} {lappend regs [format %02X [debug read "PSG regs" $r]]}
 puts $::f [join $regs " "]
 incr ::left -1
 if {$::left==0} {close $::f; after time 0.1 next_song}
}
proc next_song {} {
 incr ::song
 if {$::song>=[llength $::ticks]} {exit}
 set ::f [open [format "%s/song%02d.txt" $::out $::song] w]
 set ::left [lindex $::ticks $::song]
 poke 0xc000 [expr {$::song==10 ? 0xfd : $::song}]   ;# 10: the hats, then song 0
}
debug set_bp $::done {} tick
after time 12 {poke 0xc000 0xfe; after time 0.2 next_song}
after time 600 {exit 1}
