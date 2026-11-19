from pathlib import Path

p = Path('build/mission/knife-kick-test')
def read(name):
    return list(map(int, (p / f'{name}.txt').read_text().split()))
assert read('left') == [0, 8], read('left')
assert read('right') == [0, 8], read('right')
assert read('away') == [1, 8], read('away')
print('OK: a correctly directed kick destroys a knife from either side')
