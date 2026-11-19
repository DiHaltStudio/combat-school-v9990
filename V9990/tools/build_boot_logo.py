#!/usr/bin/env python3
"""The DiHalt logo shown at power-on (src/boot_logo.asm), as in the Chase HQ
port (../chasehq-v9990/V9990-B1BP6: src/rom.asm Intro, tools/mkintro.py and
tools/mksound.py).

assets/boot/dihalt_logo-b1.png: 256x212, indexed, the indices are the
V9990's BD8 colours (GGGRRRBB). Written as runs: count (1-255), byte; a
count of 0 ends. build/boot/logo.rle.

assets/boot/logo.vgm: its PSG music. Frame by frame at 50 Hz, the periods
scaled to the MSX's PSG clock, only the registers that change: A0 rr dd ...
63 (end of a frame) ... 66 (end); cut at 7.20 s with a 0.5 s fade, as Chase
HQ. build/boot/logo-music.bin."""
import struct
from pathlib import Path
from PIL import Image, ImageOps

SRC = Path('assets/boot')
OUT = Path('build/boot')
MSX_CLOCK = 1789772
FRAME = 882                     # VGM samples per 50 Hz frame
CUT, FADE = 7.20, 0.5
OPENING_BANKS = (28, 29, 30, 31, 32, 33, 58, 59)
OPENING_WIDTH, OPENING_HEIGHT = 288, 424
BANK_SIZE = 0x4000


def logo_rle():
    im = Image.open(SRC / 'dihalt_logo-b1.png')
    assert im.mode == 'P' and im.size == (256, 212)
    data = bytes(im.getdata())
    out, i = bytearray(), 0
    while i < len(data):
        j = i
        while j < len(data) and data[j] == data[i] and j - i < 255:
            j += 1
        out += bytes((j - i, data[i]))
        i = j
    return bytes(out + b'\0')


def build_opening():
    """Pack the portrait into BD8; the V9990 loader supplies the side margins."""
    with Image.open('assets/opening.jpg') as source:
        art = ImageOps.contain(ImageOps.exif_transpose(source).convert('RGB'),
                               (OPENING_WIDTH, OPENING_HEIGHT), Image.Resampling.LANCZOS)
    canvas = Image.new('RGB', (OPENING_WIDTH, OPENING_HEIGHT))
    canvas.paste(art, ((OPENING_WIDTH - art.width) // 2, (OPENING_HEIGHT - art.height) // 2))
    pixels = bytes(((g * 7 + 127) // 255 << 5) |
                   ((r * 7 + 127) // 255 << 2) |
                   ((b * 3 + 127) // 255) for r, g, b in canvas.getdata())
    rows_per_bank = BANK_SIZE // OPENING_WIDTH
    assert len(OPENING_BANKS) * rows_per_bank >= OPENING_HEIGHT
    manifest = bytearray()
    table = [f'OPENING_WIDTH equ {OPENING_WIDTH}', 'opening_banks:']
    for bank, first_row in zip(OPENING_BANKS, range(0, OPENING_HEIGHT, rows_per_bank)):
        rows = min(rows_per_bank, OPENING_HEIGHT - first_row)
        data = pixels[first_row * OPENING_WIDTH:(first_row + rows) * OPENING_WIDTH]
        manifest.extend(bytes([bank]) + data.ljust(BANK_SIZE, b'\xff'))
        table.append(f'        db {bank},{rows}')
    table.append('        db 0')
    (OUT / 'opening-banks.bin').write_bytes(manifest)
    (OUT / 'opening.inc').write_text('\n'.join(table) + '\n')


def parse(path):
    d = path.read_bytes()
    assert d[:4] == b'Vgm '
    ver = struct.unpack_from('<I', d, 8)[0]
    i = 0x34 + struct.unpack_from('<I', d, 0x34)[0] if ver >= 0x150 else 0x40
    clock = struct.unpack_from('<I', d, 0x74)[0] & 0x3FFFFFFF
    events, t = [], 0
    while True:
        c = d[i]
        if c == 0xA0:
            events.append((t, d[i + 1] & 0x7F, d[i + 2]))
            i += 3
        elif c == 0x61:
            t += struct.unpack_from('<H', d, i + 1)[0]
            i += 3
        elif c == 0x62:
            t, i = t + 735, i + 1
        elif c == 0x63:
            t, i = t + FRAME, i + 1
        elif 0x70 <= c <= 0x7F:
            t, i = t + (c & 15) + 1, i + 1
        elif c == 0x66:
            return events, t, clock
        else:
            raise SystemExit(f'{path}: VGM command {c:02X}')


def music():
    events, total, clock = parse(SRC / 'logo.vgm')
    n = (total + FRAME - 1) // FRAME
    per = [dict() for _ in range(n)]
    for t, r, v in events:
        if r < 14:
            per[min(t // FRAME, n - 1)][r] = v
    k = MSX_CLOCK / clock
    st, frames = {}, []
    for regs in per:
        st.update(regs)
        sc = dict(regs)
        for lo, hi in ((0, 1), (2, 3), (4, 5)):
            if lo in regs or hi in regs:
                p = st.get(lo, 0) | (st.get(hi, 0) & 15) << 8
                p = min(4095, max(1, round(p * k))) if p else 0
                sc[lo], sc[hi] = p & 255, p >> 8
        if 6 in regs:
            sc[6] = min(31, round((st[6] & 31) * k))
        if 11 in regs or 12 in regs:
            p = min(65535, round((st.get(11, 0) | st.get(12, 0) << 8) * k))
            sc[11], sc[12] = p & 255, p >> 8
        frames.append(sc)
    a, f = round(CUT * 50), round(FADE * 50)
    frames, st = [dict(r) for r in frames[:a + f]], {}
    for i, regs in enumerate(frames):
        st.update(regs)
        if i >= a:
            q = (a + f - i - 1) / (f + 1)
            for r in (8, 9, 10):
                v = st.get(r, 0)
                regs[r] = round((v & 15) * q) if v < 16 else 0
    data, shadow = bytearray(), {}
    for regs in frames:
        for r in sorted(regs):
            v = regs[r]
            if r == 13 or shadow.get(r) != v:
                data += bytes((0xA0, r, v))
                shadow[r] = v
        data.append(0x63)
    data.append(0x66)
    return bytes(data), len(frames)


OUT.mkdir(parents=True, exist_ok=True)
rle = logo_rle()
(OUT / 'logo.rle').write_bytes(rle)
tune, frames = music()
(OUT / 'logo-music.bin').write_bytes(tune)
build_opening()
print(f'boot logo: {len(rle)} bytes; music {frames} frames ({frames / 50:.1f} s), {len(tune)} bytes')
