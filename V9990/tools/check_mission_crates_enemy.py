from pathlib import Path

root = Path('build/mission/crates-enemy-test')
left = list(map(int, (root / 'left.txt').read_text().split()))
right = list(map(int, (root / 'right.txt').read_text().split()))
assert left[1:] == [8, 1], left
assert right[1:] == [8, 1], right
print('OK: ground assailants cannot hit a player on the crates from either side')
