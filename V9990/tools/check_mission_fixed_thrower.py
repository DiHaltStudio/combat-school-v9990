from pathlib import Path
p=Path('build/mission/fixed-thrower-test')
def state(name):return list(map(int,(p/f'{name}.txt').read_text().split()))
a,b,c=map(state,('initial','moved','defeated'))
assert a==[1,1,661,8] and b==a,(a,b)
assert c==[1,4,661,8],c
print('OK: second-crate thrower stays at its post and does not respawn after defeat')
