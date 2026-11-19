from pathlib import Path
p=Path('build/mission/late-zone-test')
def state(name):return list(map(int,(p/f'{name}.txt').read_text().split()))
a,b,c=map(state,('alive','spawned','later'))
assert a[0]==0 and a[1]==0,a
assert b[0:3]==[1,1,661] and b[3]==8,b
assert c[0:3]==[1,1,661] and c[6]==8,c
bottle=state('bottle')
assert bottle[0:3]==[1,1,661] and bottle[6]==8,bottle
print('OK: later attacker and wave appear even while the first attacker is alive; bottle launches')
