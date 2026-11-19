# Automated runs skip the power-on screens (src/boot_logo.asm): BOOT_SKIP
# (D0FCh) = A5h, written until the cartridge has started.
proc skip_boot_poll {} {
    poke 0xd0fc 0xa5
    if {[machine_info time] < 4} {after time 0.02 skip_boot_poll}
}
skip_boot_poll
