#!/usr/bin/env python3
"""Build the race bonus table and the next-event map for the MegaROM."""
from pathlib import Path
from PIL import Image, ImageDraw

out = Path('build/demo')
base = Image.open('assets/progression/bonus.png').convert('RGB')
shoot_bonus = Image.open('assets/progression/shoot-bonus.png').convert('RGB')
event_map = Image.open('assets/progression/map.png').convert('RGB')
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from arcade_font import draw_text
variants = []
# assets/progression/bonus.png: the arcade's own screen, pixel exact (MAME,
# build/mame-finish frame 0200, rows 11..222: without the 1P/HI score line).
# Its arrow and 1P are glyphs of the text font at x 208; the arcade put them
# on the 2 TO 3 SEC row: erased, then drawn on the row of this race.
rows_arcade = (197, 181, 165, 149, 133, 117)  # row tops, bonus seconds 0..5
def marker(draw, y):
    """The arrow and 1P of the arcade (x 208..231, its shadow to 232):
    a patch of 26x8 pixels, 13 bytes a row (src/demo_b1.asm progress_marker)."""
    draw_text(draw, 208, y, '<1P', (239, 239, 239), scale=2, shadow=(33, 33, 33))
for selected in range(6):
    image = base.copy()
    draw = ImageDraw.Draw(image)
    draw.rectangle((207, 112, 240, 205), fill='black')
    marker(draw, rows_arcade[selected])
    variants.append(image)
rows = rows_arcade   # also the recorded bonus screens below (1 pixel off)

from arcade_palette import arcade_palette
# The Step 1 bonus screen is the arcade's (27 colours); the other bonus
# screens share this palette.
bonus_palette = arcade_palette(base)
# The event map is the arcade's (MAME, build/mame-map frame 0029, rows
# bands squeezed to 212 lines, tools/extract_progress_maps.py: 14 colours), plus black (pen 0) and the white of the lit square,
# pen 9 (the fill 99h of progress_map_light, src/demo_b1.asm).
map_palette=arcade_palette(event_map, 14)
map_palette.remove((0,0,0)) if (0,0,0) in map_palette else None
map_palette=[(0,0,0)]+map_palette
map_palette.insert(9,(239,239,239))
assert len(map_palette)==16
def reference(colours):
    pal=[component for rgb in colours for component in rgb]
    ref=Image.new('P',(1,1));ref.putpalette(pal+[0]*(768-len(pal)))
    return ref,pal
bonus_ref,bonus_pal=reference(bonus_palette)
map_ref,map_pal=reference(map_palette)
map_on=event_map.copy()
map_off=event_map.copy()
# The bottom square belongs to STEP 1; alternate white and the normal gold.
ImageDraw.Draw(map_on).rectangle((16,182,31,210),fill=(239,239,239))
ImageDraw.Draw(map_off).rectangle((16,182,31,210),fill=(206,148,0))
frames = ([image.quantize(palette=bonus_ref,dither=Image.Dither.NONE) for image in variants]
          +[image.quantize(palette=map_ref,dither=Image.Dither.NONE) for image in (map_on,map_off)])
shoot_variants=[]
for selected in range(6):
    image=shoot_bonus.copy(); pixels=image.load(); draw=ImageDraw.Draw(image)
    draw.rectangle((207,112,240,205),fill='black')
    # The arcade's capture (MAME, build/mame-shoot frame 0318, rows 11..222)
    # shows the 56 TO 59 row lit in red: every bonus value back to white.
    for y in range(113,204):
        for x in range(95,207):
            if pixels[x,y]==(247,0,0): pixels[x,y]=(239,239,239)
    marker(draw,rows[selected])
    shoot_variants.append(image.quantize(palette=bonus_ref,dither=Image.Dither.NONE))
map_two_on=map_on.copy();map_two_off=map_off.copy()
ImageDraw.Draw(map_two_on).rectangle((16,152,31,180),fill=(239,239,239))
ImageDraw.Draw(map_two_off).rectangle((16,152,31,180),fill=(206,148,0))
shoot_frames=shoot_variants+[im.quantize(palette=map_ref,dither=Image.Dither.NONE) for im in (map_two_on,map_two_off)]
data = bytearray()
for image in frames:
    pixels=list(image.getdata())
    assert max(pixels)<16
    raw=bytes(pixels[i]*16+pixels[i+1] for i in range(0,len(pixels),2))
    data.extend(raw+bytes([255])*(32768-len(raw)))
(out/'progress.bin').write_bytes(data)
shoot_data=bytearray()
for image in shoot_frames:
    pixels=list(image.getdata())
    assert max(pixels)<16
    raw=bytes(pixels[i]*16+pixels[i+1] for i in range(0,len(pixels),2))
    shoot_data.extend(raw+bytes([255])*(32768-len(raw)))
(out/'shoot-progress.bin').write_bytes(shoot_data)
# Store one base image per bonus table and one map instead of 16 complete
# screens. The reference files above remain available for pixel-exact tests.
def compact_bonus(images):
    base = images[0].copy()
    ImageDraw.Draw(base).rectangle((208,rows[0],233,rows[0]+7),fill=0)
    bp=list(base.getdata())
    raw=bytearray(bp[i]*16+bp[i+1] for i in range(0,len(bp),2))
    patches=bytearray()
    for image,y in zip(images,rows):
        px=list(image.getdata())
        for py in range(y,y+8):
            for x in range(208,234,2):
                patches.append(px[py*256+x]*16+px[py*256+x+1])
        reconstructed=bytearray(raw)
        patch=patches[-104:]
        for py in range(8):
            offset=(y+py)*128+104
            reconstructed[offset:offset+13]=patch[py*13:(py+1)*13]
        expected=bytes(px[i]*16+px[i+1] for i in range(0,len(px),2))
        assert reconstructed==expected, 'bonus marker extends outside patch'
    return bytes(raw+patches+bytes([255])*(32768-len(raw)-len(patches)))
map_base=frames[7]
mp=list(map_base.getdata())
map_raw=bytes(mp[i]*16+mp[i+1] for i in range(0,len(mp),2))
map_raw+=bytes([255])*(32768-len(map_raw))
(out/'progress-compact.bin').write_bytes(compact_bonus(frames[:6])+compact_bonus(shoot_frames[:6])+map_raw)
(out/'progress-palette.bin').write_bytes(bytes(v>>3 for v in bonus_pal))
(out/'map-palette.bin').write_bytes(bytes(v>>3 for v in map_pal))
(out/'progress.inc').write_text(f'PROGRESS_BLACK equ {frames[0].getpixel((0,0))}\n')
frames[2].save(out/'bonus-preview.png')
frames[-2].save(out/'map-preview.png')
shoot_frames[2].save(out/'shoot-bonus-preview.png')
shoot_frames[-2].save(out/'map-two-preview.png')

# Step 4 uses different hit brackets from the first shooting range.
step4_variants=[]
labels=('52 TO 53','54 TO 55','56 TO 57','58 TO 59','60 TO 63','OVER 64')
for selected in range(6):
    image=shoot_variants[selected].convert('RGB')
    draw=ImageDraw.Draw(image)
    draw.rectangle((0,117,94,210),fill='black')   # the recorded labels, from the arcade's row 117
    for y,label in zip(rows,labels):
        draw_text(draw,0,y,label,(247,0,0),scale=2,shadow=(33,33,33))   # x 0, as the arcade's table
    step4_variants.append(image.quantize(palette=bonus_ref,dither=Image.Dither.NONE))
(out/'step4-bonus-compact.bin').write_bytes(compact_bonus(step4_variants))
step4_variants[3].save(out/'step4-bonus-preview.png')

# Step 6 has two rows of 16 qualifying targets and one bonus bracket per
# additional target. Reuse the portraits, palette and marker patches.
step6_variants=[]
for selected in range(6):
    image=shoot_variants[selected].convert('RGB')
    draw=ImageDraw.Draw(image)
    draw.rectangle((0,117,94,210),fill='black')   # the recorded labels, from the arcade's row 117
    for y,label in zip(rows,('32','33','34','35','36','OVER 36')):
        draw_text(draw,0,y,label,(247,0,0),scale=2,shadow=(33,33,33))   # x 0, as the arcade's table
    step6_variants.append(image.quantize(palette=bonus_ref,dither=Image.Dither.NONE))
(out/'step6-bonus-compact.bin').write_bytes(compact_bonus(step6_variants))
step6_variants[3].save(out/'step6-bonus-preview.png')
