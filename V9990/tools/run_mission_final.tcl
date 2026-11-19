# Callback invoked by run_mission.tcl when the integrated mission is ready.
# Arrange the scene once in RAM, then let the cartridge run normally.
proc mission_ready {} {
 foreach a {0xc851 0xc871 0xc891 0xc8c1 0xc8e9 0xc911 0xc921 0xc941 0xc951 0xc961 0xc971} {poke $a 5}
 foreach a {0xc8a2 0xca02 0xc8dd 0xc8d4 0xc823 0xc857 0xc803 0xc804 0xc80a 0xc981} {poke $a 0}
 poke 0xc8da 1; poke 0xc8d0 1; poke 0xc930 1; poke 0xc8e0 1; poke 0xc900 1; poke 0xc990 49
 poke 0xc840 109; poke 0xc841 0; poke 0xc800 0; poke 0xc801 96
 poke 0xc856 8; poke 0xca26 0; poke 0xca27 0
 if {[info exists ::env(ROM_FINAL_TEST)]} {after time 0.5 mission_final_check}
}
proc mission_final_check {} {
 if {[peek 0xc981]!=1 || [peek 0xc986]!=8} {error "Final fight did not initialise"}
 set f [open $::env(ROM_FINAL_TEST) w];puts $f "OK: boss active with 8 health";close $f
 exit
}
