from pathlib import Path

p = Path('build/mission/second-crate-test')
def state(name):
    return list(map(int, (p / f'{name}.txt').read_text().split()))
right, top, left, top_left, exit_right = map(state, ('blocked-right','atop','blocked-left','atop-left','exit-right'))
assert 208 <= right[0] <= 212 and right[1:] == [0,0,8], right
assert 162 <= top[0] < 197 and top[1:] == [2,0,8], top
assert 146 <= left[0] <= 150 and left[1:] == [0,0,8], left
assert 162 <= top_left[0] < 197 and top_left[1:] == [2,0,8], top_left
assert exit_right[0] >= 215 and exit_right[1:] == [0,0,8], exit_right
print('OK: second crate blocks both sides and supports landing and leaving')
