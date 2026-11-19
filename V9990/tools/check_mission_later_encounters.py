from pathlib import Path
p=Path('build/mission/later-encounters-test')
def state(name):return list(map(int,(p/f'{name}.txt').read_text().split()))
a,b,c,d=map(state,('before','first','defeated','returned'))
assert a[0]==0,a
assert b[:6]==[1,1,0,0,0,0],b
assert c[0]==1 and c[1] in (4,5) and c[2:6]==[0,0,0,0],c
assert d[0]==1 and d[1] in (4,5) and d[2:6]==[0,0,0,0],d
assert all(x[6]==8 for x in (a,b,c,d)),(a,b,c,d)
print('OK: one later attacker spawns once, with no reinforcements after defeat')
