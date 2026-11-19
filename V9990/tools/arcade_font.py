"""The arcade's 8x8 text font for every text the tools draw, as the arcade
does: one font in all its screens, glyphs in white or red with a dark shadow.

assets/mission/ending-font.png (tools/extract_mission_ending.py): the glyphs
of GLYPHS in a row, glyph pixels (239,239,239), shadow (33,33,33).

draw_text(draw, x, y, text, colour, scale=1, shadow=None) replaces the old
tools/pixel_font.py call: same advance (8 pixels a character), 8 rows high
(the old font was 10). colour is the pen (index or RGB) for the glyph; the
shadow goes in `shadow` or, when not given, in the darkest non-zero pen of
the image's palette (pen 0 is transparent in the blitter copies); in an RGB
image, (33,33,33). scale=1 keeps the old half-size 3x5 font (labels copied with narrower
widths); any other scale draws the arcade font."""
from pathlib import Path
from PIL import Image

GLYPHS = 'ACDEFGHIKLMNOPRSTUVY0123456789().!>BJQWXZ?#'
_FONT = Image.open(Path(__file__).resolve().parents[1] / 'assets/mission/ending-font.png').convert('RGB')
_WHITE, _SHADOW = (239, 239, 239), (33, 33, 33)
# Glyphs not in the ending's font, as the arcade draws them ('#' glyph,
# 's' shadow). '<': the arrow before 1P on the bonus screens (MAME,
# build/mame-finish frame 0200, x 208, y 192).
EXTRA = {'<': ('...#....', '..##....', '.######.', '#######s',
               '#######s', '.######s', '..##ssss', '...#s...'),
         # The ending's J was extracted with its whole cell shadowed: its
         # glyph, with the shadow one pixel right and down.
         'J': ('....####', '.....##s', '.....##s', '.....##s',
               '.....##s', '##...##s', '.#####ss', '..sssss.')}


def shadow_pen(palette):
    """The pen closest to the arcade's shadow grey, pen 0 left out (it is
    transparent in the blitter copies). palette: flat [r, g, b, ...]."""
    used = range(1, len(palette) // 3)
    return min(used, key=lambda i: sum((palette[3 * i + k] - _SHADOW[k]) ** 2 for k in range(3)))


def _shadow_pen(image):
    if image.mode != 'P':
        return _SHADOW
    pal = (image.getpalette() or [])[:768]
    if len(pal) < 6:
        raise ValueError('arcade_font: an image without palette needs shadow=shadow_pen(palette)')
    return shadow_pen(pal)


def draw_text(draw, x, y, text, colour, scale=1, shadow=None):
    if scale == 1:
        # Half-size labels (4 pixels a character, Step 3 BONUS/SEC/TIME UP):
        # the code copies them with narrower widths; the small font stays.
        from pixel_font import draw_text as small
        return small(draw, x, y, text, colour, 1)
    image = draw._image
    if shadow is None:
        shadow = _shadow_pen(image)
    for i, char in enumerate(text):
        if char == ' ':
            continue
        if char in EXTRA:
            rows = EXTRA[char]
            pixel = lambda gx, gy: {'#': _WHITE, 's': _SHADOW}.get(rows[gy][gx])
        else:
            k = GLYPHS.index(char) * 8
            pixel = lambda gx, gy, k=k: _FONT.getpixel((k + gx, gy))
        for gy in range(8):
            for gx in range(8):
                c = pixel(gx, gy)
                if c == _WHITE:
                    draw.point((x + i * 8 + gx, y + gy), fill=colour)
                elif c == _SHADOW:
                    draw.point((x + i * 8 + gx, y + gy), fill=shadow)
