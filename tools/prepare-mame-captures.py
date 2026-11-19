#!/usr/bin/env python3
"""Archive generated resources when capture inputs change; retain the Python venv."""
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[1]
build = root / 'V9990/build'
marker = build / 'capture-inputs.json'
revision = (root / 'tools/mame-revision').read_text().strip()
for name in (
    'ARCADE/original/combatsc.zip',
    'musicPsg/driver/bank3_pristine.bin',
    'musicPsg/regs/08_castigo_y_mision.txt',
):
    if not (root / name).is_file():
        raise SystemExit(f'Missing local build input: {name}. See docs/BUILDING.md.')
files = [root / 'ARCADE/original/combatsc.zip', root / 'tools/mame.Containerfile',
         root / 'tools/mame-build.mk', root / 'tools/mame.sh',
         *sorted((root / 'V9990/tools').glob('mame*.lua'))]
state = {'mame_revision': revision, 'files': {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
if marker.exists() and json.loads(marker.read_text()) == state:
    raise SystemExit(0)
build.mkdir(parents=True, exist_ok=True)
old = [p for p in build.iterdir() if p.name not in ('venv', 'manual')]
if old:
    archive = root / 'build/capture-archives' / datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    archive.mkdir(parents=True)
    for p in old:
        shutil.move(str(p), archive / p.name)
    print('Previous generated resources archived in', archive)
marker.write_text(json.dumps(state, indent=2) + '\n')
print('Capture inputs pinned to Debian MAME 0.264+dfsg.1-1')
