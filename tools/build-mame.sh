#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
revision=$(cat "$root/tools/mame-revision")
image=localhost/combatschool-mame:0264
cd "$root"
source_git="$root/build/mame-git"
command -v podman >/dev/null || { echo 'Install Podman to build and run the pinned MAME' >&2; exit 1; }
podman image exists "$image" || podman build -t "$image" -f tools/mame.Containerfile tools
mkdir -p build
if [[ ! -f build/mame-source/.prepared ]]; then
    mkdir -p build/mame-source
    if [[ ! -d "$source_git/.git" ]]; then
        git init -q "$source_git"
    fi
    if ! git -C "$source_git" cat-file -e "$revision^{commit}" 2>/dev/null; then
        git -C "$source_git" -c http.version=HTTP/1.1 fetch --depth 1 \
            https://salsa.debian.org/games-team/mame.git refs/tags/debian/0.264+dfsg.1-1
        [[ $(git -C "$source_git" rev-parse 'FETCH_HEAD^{commit}') == "$revision" ]] ||
            { echo 'Wrong MAME source revision' >&2; exit 1; }
    fi
    git -C "$source_git" archive "$revision" | tar -x -C build/mame-source
    podman run --rm --userns=keep-id -v "$root:$root" -w "$root/build/mame-source" "$image" sh -c '
        while read -r patchname rest; do
            case "$patchname" in ""|\#*) continue ;; esac
            patch -p1 < "debian/patches/$patchname" || exit 1
        done < debian/patches/series'
    printf '%s\n' "$revision" > build/mame-source/.prepared
fi
podman run --rm --userns=keep-id -v "$root:$root" -w "$root/build/mame-source" "$image" make -f "$root/tools/mame-build.mk" -j"${MAME_JOBS:-2}"
podman run --rm "$image" dpkg-query -W > "$root/build/mame-packages.txt"
sha256sum "$root/build/mame-source/combatschool" > "$root/build/mame-binary.sha256"
