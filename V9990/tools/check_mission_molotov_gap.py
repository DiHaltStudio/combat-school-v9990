from pathlib import Path

result = list(map(int, Path('build/mission/molotov-gap-test/result.txt').read_text().split()))
x, projectile, health, remaining, jumped, frames = result
assert x < 873 and projectile == 0 and health == 8 and remaining > 0 and jumped == 1, result
print(f'OK: player crosses the crate using movement and jump before the next bottle ({frames} display frames)')
