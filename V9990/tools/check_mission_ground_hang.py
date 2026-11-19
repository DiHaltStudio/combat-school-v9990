from pathlib import Path
p=Path('build/mission/ground-hang-test')
def state(name):return list(map(int,(p/f'{name}.txt').read_text().split()))
outside,caught,dropped=map(state,('outside','caught','dropped'))
assert outside[0]==0 and outside[2]==8,outside
assert caught[0]==1 and caught[2]==8,caught
assert dropped[0]==0 and dropped[2]==8,dropped
print('OK: ground jump catches under the pipe, releases, and cannot catch outside')
