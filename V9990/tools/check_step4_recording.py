from pathlib import Path
import json

raw = Path('build/step4/recorded-sequence.bin').read_bytes()[:json.loads(Path('assets/step4/recorded-sequence.json').read_text())['bytes']]
meta = json.loads(Path('assets/step4/recorded-sequence.json').read_text())
frames = []
offsets = []
pos = 0
for _ in range(meta['frames']):
    count = raw[pos]
    pos += 1
    frame = [tuple(raw[pos+i*4:pos+i*4+4]) for i in range(count)]
    pos += count*4
    assert count <= 16 and all(a[0] < meta["tracks"] and 1 <= a[3] >> 2 <= 5 and a[3] < 24 for a in frame)
    assert len({a[0] for a in frame}) == count
    frames.append(frame)
    offsets.append(pos)
assert pos == len(raw)
# The MAME recording (tools/build_step4_robots.py): every robot keeps one
# identity without gaps, so none blinks out and back, and it appears and
# leaves only at the screen sides or at the horizon (or at the recording's
# start and end).
tracks = {}
for tick, frame in enumerate(frames):
    for entry in frame:
        tracks.setdefault(entry[0], []).append((tick, entry))
assert len(tracks) == meta['tracks']
for ident, samples in tracks.items():
    ticks = [tick for tick, _ in samples]
    assert ticks == list(range(ticks[0], ticks[-1] + 1)), ident
    for tick, (_, x, y, _) in (samples[0], samples[-1]):
        assert tick == 32 or tick >= 1313 or x <= 16 or x >= 228 or y <= 62, (ident, tick, x, y)
# No bounces: the feet (top + the drawn image's height, from the size in
# bits 2-4 of the view byte) never go up and down while a robot advances.
sets = Path('build/step4/target-sets.bin').read_bytes()
def feet(entry):
    view_set, band = (0, 1, 2, 0)[entry[3] & 3], (entry[3] >> 2) - 1
    return entry[2] + sets[16 * view_set + 3 + 3 * band]
for ident, samples in tracks.items():
    ys = [feet(entry) for _, entry in samples if entry[2] < 164]
    for a, b, c in zip(ys, ys[1:], ys[2:]):
        assert (b - a) * (c - b) >= 0 or max(abs(b - a), abs(c - b)) < 2, (ident, a, b, c)
values = list(map(int, Path('build/step4/timeline.txt').read_text().split()))
assert len(values) == 36, values
for tick, cursor, bank, count in zip(*[iter(values)]*4):
    offset = offsets[tick-1]
    assert (bank, cursor, count) == (4+offset//16384, 0x8000+offset%16384, len(frames[tick-1])), (tick,bank,cursor,count,offset,len(frames[tick-1]))
assert values[-2] == 5, values
print('OK: 1380 frames validated, sampled playback and ROM bank switch match recording')
