from pathlib import Path
rows=[list(map(int,x.split())) for x in Path('build/mission/grab-load-test/result.txt').read_text().splitlines()]
assert [r[0] for r in rows]==[0,1,2,3],rows
assert all(r[2]==8 for r in rows),rows
assert max(r[1] for r in rows)-min(r[1] for r in rows)<=2,rows
print('OK: frames until pipe catch with clear/attacker+fire/+bottle/+fallen enemies:',[r[1] for r in rows])
