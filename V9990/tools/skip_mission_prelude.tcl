# Tests of the mission only: skip the screens before the mission
# (src/mission_prelude.asm reads D0FF = A5 at its start). Played normally,
# RAM never holds that value there at power-on.
proc skip_mission_prelude {} {
 poke 0xd0ff 0xa5
 if {[machine_info time]<12} {after frame skip_mission_prelude}
}
after frame skip_mission_prelude
