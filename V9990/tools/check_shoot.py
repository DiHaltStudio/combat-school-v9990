from pathlib import Path

rows={parts[0]:list(map(int,parts[1:])) for parts in (line.split() for line in Path('build/demo/shoot-test/trace.txt').read_text().splitlines())}
assert rows['start'][:2]==[39,1], rows
assert rows['moved'][0]>rows['start'][2], rows
mask=rows['start'][4]
assert mask in (3,7,15) and rows['held']==[1,mask-1], rows
assert rows['hit'][0]==2 and rows['hit'][1] in (mask-3,3,7,15), rows
print('OK: gallery transition, bonus time, cursor movement and two separate hits')
