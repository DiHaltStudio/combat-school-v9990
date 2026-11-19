#!/bin/sh
# usage: capture.sh <Combat School - 128k.tzx> <ROM dir with spec128/zx128_0.rom, zx128_1.rom> <output dir>
set -e
tzx=$(realpath "$1"); roms=$(realpath "$2"); out=$(realpath -m "$3"); here=$(dirname "$(realpath "$0")")
mkdir -p "$out"
SDL_VIDEODRIVER=dummy CAP_DIR="$out" exec mame spec128 -rompath "$roms" -cass "$tzx" -video none -sound none -nothrottle -skip_gameinfo \
  -nvram_directory "$out/.mame" -cfg_directory "$out/.mame" -autoboot_script "$here/capture_ay.lua" -seconds_to_run 0
