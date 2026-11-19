#!/usr/bin/env python3
"""Penalty (chin-ups) data for src/penalty.asm from assets/penalty.

Two 16-colour palettes: the scene (background, poses, texts and digits;
index 0 is black and transparent for the poses) and the instructor
portrait. Every image is packed 4 bits per pixel and RLE-coded as
(count, byte) pairs ended by a zero count, the format of upload_rle; the
streams are concatenated and may cross from one 16 KiB bank to the next.

Outputs in build/penalty:
  data.bin      the streams, after the code from offset 0x1800 of the
                module's first bank (see penalty.inc)
  penalty.inc   stream addresses (bank, offset), palettes and pose table
"""
from pathlib import Path
from PIL import Image
import numpy as np

A = Path('assets/penalty')
P = Path('build/penalty')
FIRST_BANK = 0                  # bank of src/penalty.asm (data from 0x1800)
START = 0x1800
PORTRAIT_STICK = (68, 78, 104, 112)     # tools/extract_penalty.py
PORTRAIT_MOUTH = (112, 68, 52, 52)


def quantise(images, colours):
    """Median-cut palette of `colours` entries plus black at index 0."""
    pixels = np.concatenate([np.asarray(im.convert('RGBA')).reshape(-1, 4) for im in images])
    pixels = pixels[(pixels[:, 3] > 0) & (pixels[:, :3].max(axis=1) > 16)][:, :3]
    sample = Image.fromarray(pixels.reshape(1, -1, 3).astype(np.uint8), 'RGB')
    pal = sample.quantize(colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).getpalette()[:3 * colours]
    return [(0, 0, 0)] + [tuple(pal[i:i + 3]) for i in range(0, 3 * colours, 3)]


def indices(image, palette, opaque_from=0, skip=None):
    """Nearest palette index; transparent pixels are 0. Opaque pixels of
    sprites avoid index 0 (opaque_from=1); `skip` is never chosen."""
    a = np.asarray(image.convert('RGBA')).astype(int)
    pal = np.array(palette[opaque_from:])
    if skip is not None:
        pal[skip - opaque_from] = (4096, 4096, 4096)
    d = ((a[:, :, None, :3] - pal[None, None]) ** 2).sum(axis=3)
    out = d.argmin(axis=2) + opaque_from
    out[a[:, :, 3] == 0] = 0
    return out


def pack(idx):
    flat = idx.reshape(-1)
    return bytes(int(flat[i]) * 16 + int(flat[i + 1]) for i in range(0, len(flat), 2))


def rle(data):
    """1..127: that many literal bytes follow; 129..255: the next byte
    repeated (control - 128) times; 0 ends the stream."""
    out = bytearray(); i = 0; lit = bytearray()
    def flush():
        while lit:
            out.append(min(127, len(lit))); out.extend(lit[:127]); del lit[:127]
    while i < len(data):
        j = i + 1
        while j < len(data) and data[j] == data[i] and j - i < 127:
            j += 1
        if j - i >= 3:
            flush(); out += bytes((128 + j - i, data[i]))
        else:
            lit.extend(data[i:j])
        i = j
    flush()
    return bytes(out + b'\0')


def overlay(base, patch, box, k, palette):
    """Full-width rows box y..y+h: the patch pixels that differ from the
    portrait, black as index 1, the rest transparent."""
    x, y, w, h = box
    new = indices(patch.crop((k * w, 0, k * w + w, h)), palette, skip=1)
    old = base[y:y + h, x:x + w]
    strip = np.zeros((h, 256), int)
    strip[:, x:x + w] = np.where(new != old, np.where(new == 0, 1, new), 0)
    return strip


def v9990_palette(palette):
    return bytes(v >> 3 for colour in palette for v in colour)


if __name__ == '__main__':
    P.mkdir(parents=True, exist_ok=True)
    scene = Image.open(A / 'scene.png'); poses = Image.open(A / 'poses.png'); labels = Image.open(A / 'labels.png').convert('RGBA')
    # The poses weigh eight times: few pixels, but NICK's orange and the
    # soldiers' light green must keep their own entries.
    scene_pal = quantise([scene] + [poses] * 8 + [labels], 15)
    portrait = Image.open(A / 'portrait.png').convert('RGB'); portrait.paste((0,0,0),(254,190,256,212)); stick = Image.open(A / 'portrait-stick.png'); mouth = Image.open(A / 'portrait-mouth.png')
    # Index 1 is an opaque black for the patches, drawn transparently.
    portrait_pal = quantise([portrait, stick, mouth], 14)
    portrait_pal.insert(1, (8, 8, 8))
    # Index 1 only erases (patches); the images themselves never use it.
    base = indices(portrait, portrait_pal, skip=1)
    sprites = Image.new('RGBA', (256, 256))
    sprites.alpha_composite(poses.convert('RGBA'), (0, 0)); sprites.alpha_composite(labels.convert('RGBA'), (0, 192))
    streams = [
        ('scene', pack(indices(scene, scene_pal))),
        ('sprites', pack(indices(sprites, scene_pal, 1))),
        ('portrait', pack(base)),
        ('stick', pack(overlay(base, stick, PORTRAIT_STICK, 0, portrait_pal))),
        ('mouth', pack(overlay(base, mouth, PORTRAIT_MOUTH, 0, portrait_pal))
                  + pack(overlay(base, mouth, PORTRAIT_MOUTH, 1, portrait_pal))),
    ]
    data = bytearray(); inc = []
    for name, raw in streams:
        enc = rle(raw)
        off = START + len(data)
        bank, offset = FIRST_BANK + off // 0x4000, 0x8000 + off % 0x4000
        inc.append(f'PEN_{name.upper()}_BANK equ {bank}\nPEN_{name.upper()}_ADDR equ 0x{offset:04x}')
        print(f'{name:9s} raw {len(raw):6d} rle {len(enc):6d}')
        data += enc
    print('total', len(data), 'bytes; with the code', (START + len(data) + 0x3fff) // 0x4000, 'banks')
    (P / 'data.bin').write_bytes(bytes(data))
    (P / 'scene-palette.bin').write_bytes(v9990_palette(scene_pal))
    (P / 'portrait-palette.bin').write_bytes(v9990_palette(portrait_pal))
    rows = [line.split() for line in (A / 'poses.txt').read_text().splitlines()]
    inc.append('; pose: atlas x, atlas y (from VRAM y 768), screen x, screen y')
    inc.append('pen_poses:')
    for k, (name, x, y) in enumerate(rows):
        inc.append(f'        db {(k % 8) * 32},{(k // 8) * 64},{x},{y}   ; {k:2d} {name}')
    red = min(range(1, 16), key=lambda i: sum((a - b) ** 2 for a, b in zip(scene_pal[i], (240, 8, 8))))
    inc.insert(0, f'POWER_RED equ 0x{red * 17:02x}')
    (P / 'penalty.inc').write_text('\n'.join(inc) + '\n')
    Image.fromarray(np.array(scene_pal, np.uint8)[indices(scene, scene_pal)]).save(P / 'scene-preview.png')
    Image.fromarray(np.array(portrait_pal, np.uint8)[indices(portrait, portrait_pal)]).save(P / 'portrait-preview.png')
