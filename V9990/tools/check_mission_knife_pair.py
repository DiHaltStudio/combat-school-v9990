from pathlib import Path
p=Path('build/mission/knife-pair-test')
def read(name): return list(map(int,(p/f'{name}.txt').read_text().split()))
a,b,c=map(read,('before','both','one'))
assert a[0]==0,a
assert b[:4]==[1,1,0,8],b
assert c[:4]==[1,1,0,8],c
assert b[4]==8 and c[4]==8,(b,c)
d=read('launched')
assert d[0]==1 and d[3]==8,d
print('OK: one blue thrower spawns once and launches a knife')
