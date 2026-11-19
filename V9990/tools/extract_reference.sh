#!/usr/bin/env bash
set -euo pipefail
video=${1:?usage: extract_reference.sh VIDEO [OUTPUT_DIR]}
out=${2:-assets/reference}
mkdir -p "$out"
ffmpeg -v error -i "$video" -vf 'fps=1/48,scale=480:360,tile=5x2' -frames:v 1 -y "$out/video-contact.png"
