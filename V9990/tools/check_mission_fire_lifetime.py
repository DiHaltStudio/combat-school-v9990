from pathlib import Path
p=Path('build/mission/fire-lifetime-test')
def state(name):return list(map(int,(p/f'{name}.txt').read_text().split()))
a,b=state('ignited'),state('sustained')
assert a[0]==2 and a[2:]==[1,8],a
assert b[0]==2 and b[2:]==[1,8] and 0<b[1]<a[1],(a,b)
print('OK: first-crate bottle ignites and fire persists for at least two emulated seconds')
