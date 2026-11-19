#!/usr/bin/env python3
"""Check the visible hand anchors and completion of a high-wall vault."""
from pathlib import Path

rows = [list(map(float, line.split())) for line in Path('build/demo/test_tall_wall-check').read_text().splitlines()]
grab = [r for r in rows if r[6] and not r[9] and r[7] == 0 and r[8] == 664]
assert grab, 'missing the raised-hand grip during high-wall ascent'
for r in grab:
    wall_edge = r[12] - 53 - (r[1] + 256 * r[2])
    assert r[10] + 30 == wall_edge and r[11] + 4 == r[13] + 43, 'raised hand detached from wall'
pull = [r for r in rows if r[6] and not r[9] and r[7] == 32 and r[8] == 664]
assert pull, 'missing pull-up pose'
for r in pull:
    wall_edge = r[12] - 53 - (r[1] + 256 * r[2])
    assert wall_edge <= r[10] + 27 < wall_edge + 33 and r[11] + 30 == r[13] + 43, 'pull-up detached from wall'
support = [r for r in rows if r[6] and r[9] and r[7] in (64, 96)]
assert {int(r[7]) for r in support} == {64, 96}, 'missing high-wall hand poses'
for r in support:
    wall_edge = r[12] - 53 - (r[1] + 256 * r[2])
    hand_x = r[10] + (21 if r[7] == 64 else 12)
    hand_y = r[11] + (43 if r[7] == 64 else 48)
    assert wall_edge <= hand_x < wall_edge + 33 and hand_y == r[13] + 43, 'hand detached from wall'
    assert r[3] == r[13], 'runner overshot the top of the wall'
assert any(r[6] and r[7] == 128 and r[9] for r in rows), 'missing push-off pose'
assert max(r[1] + 256 * r[2] for r in rows) > 1030, 'runner did not leave the wall'
low = [list(map(float, line.split())) for line in Path('build/demo/test_vault_auto-check').read_text().splitlines()]
assert all(r[10] >= 92 for r in low if r[6] and r[9] and r[7] in (64, 96)), 'low-wall support moved backwards'
print('OK: high-wall support anchors and push-off')
