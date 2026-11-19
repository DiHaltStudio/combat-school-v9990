from pathlib import Path
p=Path('build/mission/third-crates-test')
def state(n):return list(map(int,(p/f'{n}.txt').read_text().split()))
a,b,c=map(state,('walking','jumping','hanging'))
assert 710<=a[0]<=714 and a[1:]==[0,8],a
assert 710<=b[0]<=714 and b[1:]==[0,8],b
assert c[0]<624 and c[1:]==[1,8],c
print('OK: walking and ground jump stop at crates; hanging passes above')
