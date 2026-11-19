# Opens the cadets' scene after the Iron-Man: loads the state saved at the
# bonus screen (savestate cadetes_bonus, made from build/demo/demo-b1.rom),
# then bonus, cadets and map at normal speed.
#   openmsx -machine Philips_NMS_8250 -ext gfx9000 -script tools/ver_escena_cadetes.tcl
set save_settings_on_exit off
after time 0.2 {
 loadstate cadetes_bonus
 set throttle on
 set videosource GFX9000
}
