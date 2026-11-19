# Show the MSX's own boot screen first. Switch once the cartridge enables
# the V9990 display (R#8 bit 7): the DiHalt logo at power-on, or the title
# screen when the logo is skipped.
proc select_game_video {} {
    if {![catch {debug read "Sunrise GFX9000 regs" 8} control] && ($control & 0x80) && ![catch {set ::videosource GFX9000}]} {return}
    after frame select_game_video
}
after frame select_game_video

# Keep openMSX's time history available for the user's Page Up/Down controls,
# even when the emulator's global reverse setting has been disabled.
proc enable_game_rewind {} {
    if {[dict get [reverse status] status] eq "disabled"} {reverse start}
    bind PAGEUP -repeat go_back_one_step
    bind PAGEDOWN -repeat go_forward_one_step
    # The laptop's numeric keypad may report its own key codes, especially
    # when Num Lock changes, rather than the dedicated Page Up/Down codes.
    bind "keyb {Keypad 9}" -repeat go_back_one_step
    bind "keyb {Keypad 3}" -repeat go_forward_one_step
}
after frame enable_game_rewind
