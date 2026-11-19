from pathlib import Path
p=Path('build/mission/later-weapons-test')
def state(name):return list(map(int,(p/f'{name}.txt').read_text().split()))
bottle=state('bottle')
assert bottle==[1,2,8],bottle
print('OK: the remaining later assailant launches a bottle')
