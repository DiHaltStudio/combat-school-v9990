from pathlib import Path
p = Path('build/mission/hang-test')
def state(name):
    return list(map(int, (p / f'{name}.txt').read_text().split()))
caught, idle, under, moved, stopped, right, dropped = map(state, ('caught','idle','under','moved','stopped','right','dropped'))
assert caught[1:4] == [1, 0, 8] and idle[5:] == caught[5:], (caught, idle)
assert under[1:4] == [1, 0, 8], under
assert moved[1:5] == [1, 0, 8, 1] and moved[0] < caught[0] - 10, (caught, moved)
assert stopped[0] == moved[0] and stopped[5:] == moved[5:], (moved, stopped)
assert right[0] > stopped[0] and right[4] == 0, (stopped, right)
assert dropped[1] == 0 and dropped[3] == 8, dropped
print('OK: jump catches pipe, cursor moves over fire, M releases')
