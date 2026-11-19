from pathlib import Path
p=Path('build/mission/fire-barrier-test')
def read(name):return list(map(int,(p/f'{name}.txt').read_text().split()))
a,b,c,d=map(read,('before','hanging','ground','third'))
assert a[:2]==[0,8],a
assert b[:3]==[1,8,1],b
assert c[:2]==[1,0],c
assert d[:2]==[1,0],d
print('OK: one flame by the second box appear with the attacker, is safe hanging and lethal on ground')
