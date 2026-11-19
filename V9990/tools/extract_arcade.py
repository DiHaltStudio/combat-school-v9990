#!/usr/bin/env python3
"""Export the two original arcade graphics regions as numbered 8x8 tiles.
The grayscale palette represents raw pen indices, not arcade colours.
"""
import argparse
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile
from PIL import Image, ImageDraw

REGIONS = {'gfx1': ('611g07.rom', '611g08.rom'),
           'gfx2': ('611g11.rom', '611g12.rom')}

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('rom', nargs='?', default=str(Path(__file__).resolve().parents[2] / 'ARCADE' / 'original' / 'combatsc.zip'))
    p.add_argument('--out', default='build/arcade-gfx')
    args = p.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    manifest = {}
    with ZipFile(args.rom) as z:
        for name, files in REGIONS.items():
            a, b = (z.read(f) for f in files)
            if len(a) != 0x40000 or len(b) != 0x40000:
                raise ValueError(f'{name}: tamaño de ROM inesperado')
            data = bytearray(len(a) * 2)
            data[0::2], data[1::2] = a, b
            manifest[name] = {'files': list(files), 'sha1': [hashlib.sha1(x).hexdigest() for x in (a,b)], 'tiles': len(data)//32}
            for start in range(0, len(data)//32, 512):
                # 32 columnas por 16 filas, celdas de 28x26 para leer el índice.
                sheet = Image.new('RGB', (896, 416), (36,36,36))
                draw = ImageDraw.Draw(sheet)
                for i in range(start, min(start+512, len(data)//32)):
                    tile = Image.new('L', (8,8))
                    pixels = []
                    for byte in data[i*32:(i+1)*32]:
                        pixels.extend(((byte >> 4)*17, (byte & 15)*17))
                    tile.putdata(pixels)
                    x, y = ((i-start)%32)*28, ((i-start)//32)*26
                    sheet.paste(tile.resize((16,16), Image.Resampling.NEAREST).convert('RGB'), (x,y))
                    draw.text((x,y+16), f'{i:04x}', fill='yellow')
                sheet.save(out / f'{name}-{start:04x}.png')
    (out/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print(json.dumps(manifest, indent=2))

if __name__ == '__main__':
    main()
