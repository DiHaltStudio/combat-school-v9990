#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
image=localhost/combatschool-mame:0264
[[ -x "$root/build/mame-source/combatschool" ]] || "$root/tools/build-mame.sh"
env_args=()
mount_args=()
if [[ -n ${XAUTHORITY:-} && -f $XAUTHORITY ]]; then
    env_args+=(--env XAUTHORITY)
    mount_args+=(-v "$XAUTHORITY:$XAUTHORITY:ro")
fi
while IFS='=' read -r name value; do
    case "$name" in
        COMBAT_*|SHOOT_*|STEP6_*|STEP7_*|MISSION_*|INTRO_*|FINISH_*|CAP_*|IRONMAN_*|LOST_*|PEN_*|NAME_*|DIRECTION_EARLY|DIST|MOVE|SIGHT_STEP|SDL_*|DISPLAY) env_args+=(--env "$name") ;;
    esac
done < <(env)
runtime=$(mktemp -d "$root/build/mame-runtime.XXXXXX")
trap 'rm -rf -- "$runtime"' EXIT
podman run --rm --userns=keep-id --network=none -v "$root:$root" -v /tmp/.X11-unix:/tmp/.X11-unix -w "$PWD" "${mount_args[@]}" "${env_args[@]}" "$image" "$root/build/mame-source/combatschool" -noreadconfig -noplugins -cfg_directory "$runtime/cfg" -nvram_directory "$runtime/nvram" "$@"
