"""Check the observable arc and a dodge before the bottle lands."""
from pathlib import Path
p = Path('build/mission/molotov-arc-test')
lines = [line.split() for line in (p/'arc.txt').read_text().splitlines()]
assert lines and lines[-1][0] == 'land', lines[-3:]
samples = [tuple(map(int, line)) for line in lines[:-1]]
assert len(samples) >= 20, len(samples)
start_y = samples[0][2]
minimum_y = min(row[2] for row in samples)
assert start_y-minimum_y >= 35, (start_y, minimum_y)
assert samples[-1][2] > minimum_y+20, (minimum_y, samples[-1])
assert samples[-1][1]-samples[0][1] >= 70, (samples[0], samples[-1])
assert all(row[3] == 8 for row in samples), samples
assert int(lines[-1][3]) == 8, lines[-1]
assert 945 <= int(lines[-1][1]) <= 965, lines[-1]
assert (p/'apex.png').exists()
assert (p/'land.png').exists()
print(f'OK: bottle rises {start_y-minimum_y}px, can be dodged, and lands beside the first crate at x={lines[-1][1]}')
