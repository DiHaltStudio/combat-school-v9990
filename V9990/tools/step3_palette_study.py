#!/usr/bin/env python3
"""Estimate a shared 16-colour palette for Step 3 reference images.

The input frames come from extract_step3_reference.sh. This produces an
inspection sheet, not gameplay assets: the images still contain arcade HUDs
and characters and must not be used as scrolling backgrounds.
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('frames', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    names = ('02', '06', '12', '16', '22', '28', '34', '38')
    images = []
    for name in names:
        source = Image.open(args.frames / f'{name}.png').convert('RGB')
        # Arcade image bounds in the supplied 1772x1075 capture.
        if source.size != (1772, 1075):
            raise ValueError(f'unexpected frame size: {source.size}')
        images.append(source.crop((180, 72, 1530, 990)).resize((256, 174), Image.Resampling.LANCZOS))
    sheet = Image.new('RGB', (4 * 256, 2 * 174))
    for i, img in enumerate(images):
        sheet.paste(img, ((i % 4) * 256, (i // 4) * 174))
    indexed = sheet.quantize(colors=16, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    args.output.mkdir(parents=True, exist_ok=True)
    indexed.save(args.output / 'palette-study.png')
    palette = indexed.getpalette()[:48]
    swatches = Image.new('RGB', (16 * 24, 24))
    draw = ImageDraw.Draw(swatches)
    for i in range(16):
        draw.rectangle((24 * i, 0, 24 * i + 23, 23), fill=tuple(palette[3*i:3*i+3]))
    swatches.save(args.output / 'palette-swatches.png')
    print(f'Wrote {args.output / "palette-study.png"} and palette-swatches.png')


if __name__ == '__main__':
    main()
