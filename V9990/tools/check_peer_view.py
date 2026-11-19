from pathlib import Path
import sys

folder=Path(sys.argv[1]); expected=int(sys.argv[2])
r=(folder/'ram.bin').read_bytes()
player_camera=r[0xc006]+256*r[0xc00c]
cpu_camera=r[0xc090]+256*r[0xc091]
cpu_x=r[0xc0a4]
relative=cpu_camera+cpu_x-player_camera
assert relative==expected, (relative,expected)
print(f'OK: opponent world position projects to x={relative}')
