# The power-on screens too (tools/skip_boot.tcl).
proc skip_boot_poll {} {
    poke 0xd0fc 0xa5
    if {[machine_info time] < 4} {after time 0.02 skip_boot_poll}
}
skip_boot_poll
# Automated gameplay scenarios press SPACE whenever the title is ready.
proc skip_title_poll {} {
    if {[peek 0xc0b3] == 1} {
        # Skip the introduction (src/demo_b1.asm show_intro).
        poke 0xd0fe 0xa5
        keymatrixdown 8 1
        after time 0.15 {keymatrixup 8 1}
    } elseif {[peek 0xc0b3] == 2 && [peek 0xc0b1] > 1} {
        # Gameplay tests do not need to wait through the presentation.
        poke 0xc0b1 1
    }
    after time 0.25 skip_title_poll
}
after time 1 skip_title_poll
