from pathlib import Path
p = Path('build/mission/molotov-spawn-test')
def read(name): return list(map(int, (p / f'{name}.txt').read_text().split()))
before, bottle, later = read('before'), read('bottle'), read('bottle-later')
assert before[0] == 0 and before[2] == 0, before
assert bottle[0] == 1 and bottle[1] == 1 and bottle[2:4] == [1, 2], bottle
assert bottle[5] == later[5] == 1076, (bottle, later)
assert bottle[6] <= 16, bottle
assert bottle[5] < bottle[7], bottle
print('OK: the attacker behind the crates remains in place while throwing a bottle')
