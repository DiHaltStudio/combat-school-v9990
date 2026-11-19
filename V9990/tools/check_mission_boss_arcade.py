"""Check the original boss trace without treating assisted player health as evidence."""
from pathlib import Path
health=[];states=set();attacks=set()
for p in sorted(Path('build/mission/boss-hit').glob('frame-*/ram.bin')):
    r=p.read_bytes()
    hp=r[0x446];state=r[0x431]
    if not health or hp!=health[-1]:health.append(hp)
    states.add(state)
    if state==7:attacks.add(int.from_bytes(r[0x450:0x452],'big'))
assert health==list(range(8,-1,-1)),health
assert {9,10,11,12,13}<=states,states
assert {0x5693,0x56a3}<=attacks,attacks
print('OK: arcade guardian health 8→0, blocked hits, recoil, fall and end states; both attack sequences')
