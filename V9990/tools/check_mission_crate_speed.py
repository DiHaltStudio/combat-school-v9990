from pathlib import Path
p=Path('build/mission')
a=[list(map(int,line.split())) for line in (p/'crate-speed-test/result.txt').read_text().splitlines()]
b=[list(map(int,line.split())) for line in (p/'crate-scroll-speed-test/result.txt').read_text().splitlines()]
assert len(a)==2 and all(x[2]==8 for x in a),a
assert len(b)==2 and all(x[2:]==[8,1] for x in b),b
assert a[1][1]<=a[0][1]+4,a
distances=[542-x[1] for x in b]
assert abs(distances[0]-distances[1])<=3,(b,distances)
print(f'OK: stationary jump {a[0][1]}/{a[1][1]} frames; scrolling {distances[0]}/{distances[1]} pixels in 2 seconds')
