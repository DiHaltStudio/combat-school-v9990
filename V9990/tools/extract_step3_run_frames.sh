#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then
    printf 'Uso: bash tools/extract_step3_run_frames.sh VIDEO\n' >&2
    exit 2
fi
mkdir -p build/step3-run-reference
ffmpeg -hide_banner -loglevel error -ss 1.3 -i "$1" -t 1 -vf fps=8 -y build/step3-run-reference/%02d.png
