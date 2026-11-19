#!/usr/bin/env bash
# Extract inspection frames from the user's arcade recording.
set -euo pipefail
if [ "$#" -ne 2 ]; then
    printf 'Uso: bash tools/extract_step3_reference.sh VIDEO DIRECTORIO\n' >&2
    exit 2
fi
video=$1
output_dir=$2
mkdir -p "$output_dir"
for second in 0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42; do
    ffmpeg -hide_banner -loglevel error -ss "$second" -i "$video" -frames:v 1 -y "$output_dir/$(printf '%02d' "$second").png"
done
