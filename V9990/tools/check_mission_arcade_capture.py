#!/usr/bin/env python3
"""Validate the sampled airborne kick and candidate enemy movement in MAME."""
from pathlib import Path
root=Path('build/mission/airkick-mame')
def capture(frame):
    path=root/f'frame-{frame:04d}'
    state=dict(line.split('=') for line in (path/'state.txt').read_text().splitlines())
    ram=(path/'ram.bin').read_bytes()
    assert len(ram)==0x1800
    return {k:int(v) for k,v in state.items()},ram
states=[capture(n)[0] for n in (4788,4792,4800,4804)]
assert all(s['state']==5 for s in states),states
assert not (states[0]['action_flags']&1) and all(s['action_flags']&1 for s in states[1:]),states
assert states[1]['x']>states[2]['x']>states[3]['x'],states
assert (states[1]['anim'],states[2]['anim'],states[3]['anim'])==(2,4,5),states
print('OK: airborne attack flag appears during jump while horizontal movement continues')
values=[]
for frame in (4796,4804,4812):
    _,ram=capture(frame)
    i=0x0c99-0x0800
    values.append((ram[i]<<8)|ram[i+1])
assert values[0]<values[1]<values[2],values
print('OK: candidate enemy object position increases across three captured frames',values)
