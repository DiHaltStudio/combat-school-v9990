"""RANKING table after two lost games (tools/test_ranking_integrated.tcl):
the arcade defaults plus both scores in order, each with its initials, the
second game's higher score above the first one's."""
import json
from pathlib import Path

p = Path('build/demo/ranking-test')
lines = (p / 'table.txt').read_text().split('\n')
assert lines[0].split() == ['67', '83'], 'signature CS'
glyphs = json.load(open('assets/mission/ending.json'))['glyphs']
table = []
for line in lines[1:11]:
    score, *name = map(int, line.split())
    table.append((score, ''.join(' ' if g == 254 else glyphs[g] for g in name)))
for place, (score, name) in enumerate(table, 1):
    print(f'{place:2d} {score:7d} {name}')
scores = [s for s, _ in table]
assert scores == sorted(scores, reverse=True), 'in order'
names = [n for _, n in table]
assert 'AAA' in names and 'BBB' in names, names
assert names[:6] == ['CTM', 'FGG', 'MDM', 'ETM', 'FTM', 'RTM'], names
assert 'MSV' in names and 'IAS' in names, names
first = table[names.index('AAA')][0]
second = table[names.index('BBB')][0]
assert 45000 <= first < 60000 <= second < 88500, (first, second)
assert names.index('BBB') < names.index('AAA')
assert names[-1] == 'IAS' and 'MSX' not in names and 'PGG' not in names, 'the two lowest left'
assert len([n for n in names if n.strip() == '']) == 0, 'the third game (no points) entered the table'
print('OK: both games in the RANKING table with their initials, the higher one above')
