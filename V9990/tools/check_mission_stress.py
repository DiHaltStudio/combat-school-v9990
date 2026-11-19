from pathlib import Path
rows = [line.split() for line in Path('build/mission/stress-test/performance.txt').read_text().splitlines()]
assert [int(row[0]) for row in rows] == list(range(6)), rows
normal, busy = int(rows[0][1]), int(rows[5][1])
assert normal > 0 and busy > 0
print(f'Normal jump: {normal} display frames; one enemy, flame and bottle: {busy} display frames')
if busy > normal * 1.3:
    print('Known limitation: the busy scene slows down; further optimization is required')
