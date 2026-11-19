set throttle off
proc check_mapper {} {
    debug write memory 0x7000 18
    set before [debug read_block memory 0x8000 16]
    debug write memory 0x7000 127
    set actual [debug read_block memory 0x8000 16]
    if {$actual ne "COMBAT-ASCII16!!"} { error "ASCII16 bank 127: unexpected data" }
    debug write memory 0x7000 1
    set bank1 [debug read_block memory 0x8000 16]
    debug write memory 0x7000 2
    set bank2 [debug read_block memory 0x8000 16]
    debug write memory 0x7000 18
    set restored [debug read_block memory 0x8000 16]
    if {$before ne $restored} {error "ASCII16 bank 18 did not restore"}
    debug write memory 0x7000 60   ;# free (58 and 59 hold the opening)
    binary scan [debug read_block memory 0x8000 16] cu* freebank
    if {$freebank ne [lrepeat 16 255]} {error "free bank 60 not empty"}
    if {$bank1 eq $actual || $bank2 eq $actual} {error "ASCII16 bank 1 not switched"}
    set f [open $::env(MAPPER_RESULT) w]
    puts $f "OK: ASCII16 banks 1, 2, 18, 60 and 127 selected"
    close $f
    exit
}
after time 15 check_mapper
