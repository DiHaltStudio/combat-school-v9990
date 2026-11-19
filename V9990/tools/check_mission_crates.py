#!/usr/bin/env python3
from pathlib import Path
p=Path('build/mission/crates-test')
def state(name):return [int(x) for x in (p/f'{name}.txt').read_text().split()]
right,top,left,top_left=(state(n) for n in ('blocked-right','atop','blocked-left','atop-left'))
assert 188<=right[0]<=192 and right[1:]==[0,0,8],right
assert 105<=top[0]<177 and top[1:]==[1,0,8],top
assert 89<=left[0]<=93 and left[1:]==[0,0,8],left
assert 105<=top_left[0]<177 and top_left[1:]==[1,0,8],top_left
exit_right=state('exit-right')
assert exit_right[0]>=195 and exit_right[1:]==[0,0,8],exit_right
print('OK: crates block both approaches, can be jumped onto and exited to the right')
