#!/usr/bin/env python3
"""Convert the cadet scene and its small arm animation to V9990 B1 data."""
from pathlib import Path
from PIL import Image

assets=Path('assets/step6')
out=Path('build/demo')
first=Image.open(assets/'cadets-1.png').convert('RGB')
second=Image.open(assets/'cadets-2.png').convert('RGB')
assert first.size==second.size==(256,212)
# The arcade's scene (MAME, build/mame-step6c snapshots 0120 and 0114,
# rows 12..223): about 32 colours, reduced together to 15 with
# tools/arcade_palette.py (exact colours, no averaging); black is pen 0.
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from arcade_palette import arcade_palette
both=Image.new('RGB',(256,424));both.paste(first,(0,0));both.paste(second,(0,212))
colours=[(0,0,0)]+[c for c in arcade_palette(both,16) if c!=(0,0,0)][:15]
pal=[component for colour in colours for component in colour]
ref=Image.new('P',(1,1)); ref.putpalette(pal+[0]*(768-len(pal)))
images=[im.quantize(palette=ref,dither=Image.Dither.NONE) for im in (first,second)]
pixels=list(images[0].getdata())
base=bytes(pixels[i]*16+pixels[i+1] for i in range(0,len(pixels),2))
patch_data=b''
for image in images:
    pixels=list(image.crop((48,106,96,158)).getdata())   # src/shoot_b1.asm step6_interlude_patch
    patch_data+=bytes(pixels[i]*16+pixels[i+1] for i in range(0,len(pixels),2))
assert len(base)==27136 and len(patch_data)==2496
(out/'step6-interlude.bin').write_bytes(base+patch_data+bytes([255])*(32768-len(base)-len(patch_data)))
(out/'step6-interlude-palette.bin').write_bytes(bytes(v>>3 for v in pal))
