from pathlib import Path
p=Path('build/mission/projectiles-test')
def read(name):return list(map(int,(p/f'{name}.txt').read_text().split()))
a,b=map(read,('both','moved'))
assert a[0:2]==[2,2] and a[3:5]==[1,1] and a[6]==8,a
assert b[0:2]==[2,2] and b[3:5]==[1,1] and b[6]==8,b
assert b[2]<a[2] and b[5]!=a[5],(a,b)
print('OK: ground fire and a knife coexist and update independently')
