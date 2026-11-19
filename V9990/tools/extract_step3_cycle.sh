#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then
    printf 'Uso: bash tools/extract_step3_cycle.sh VIDEO\n' >&2
    exit 2
fi
mkdir -p build/step3-analysis/mame
ffmpeg -hide_banner -loglevel error -ss 1 -i "$1" -t 1 -vf fps=20 -y build/step3-analysis/mame/%02d.png
python3 tools/extract_step3_cycle.py
