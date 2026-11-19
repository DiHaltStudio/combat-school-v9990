set throttle off
after time 1 {set videosource GFX9000}
set ::out $::env(SHOOT_OUT)
file mkdir $::out
set ::f [open $::out/trace.txt w]
after time 12 {
    poke 0xc0df 8
    poke 0xc0de 0
    poke 0xc0d5 1
    poke 0xc095 1
}
proc wait_range {} {
    if {[peek 0xc418] == 4} {
        puts $::f "start [peek 0xc435] [peek 0xc43a] [peek 0xc430] [peek 0xc431] [peek 0xc432]"
        after time 0.5 {keymatrixdown 8 128}
        after time 0.8 {keymatrixup 8 128}
        after time 1.0 {
            puts $::f "moved [peek 0xc430] [peek 0xc431]"
            poke 0xc430 [peek 0xc44a]
            poke 0xc431 [peek 0xc43b]
            keymatrixdown 8 1
        }
        after time 1.5 {
            puts $::f "held [peek 0xc434] [peek 0xc432]"
            keymatrixup 8 1
        }
        after time 1.7 {
            poke 0xc430 [peek 0xc44b]
            poke 0xc431 [peek 0xc43b]
            keymatrixdown 8 1
        }
        after time 1.85 {keymatrixup 8 1}
        after time 2.1 {
            puts $::f "hit [peek 0xc434] [peek 0xc432]"
            screenshot -raw $::out/range.png
            foreach {name dev size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64 pal "Sunrise GFX9000 palette" 256} {
                set h [open $::out/$name.bin w]; fconfigure $h -translation binary
                puts -nonewline $h [debug read_block $dev 0 $size]; close $h
            }
            close $::f
            exit
        }
    } else {
        if {[machine_info time] > 30} {exit 1}
        after frame wait_range
    }
}
after time 12.1 wait_range
