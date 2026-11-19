"""Shared 16x16 transparent impact effect used by combat and mission."""
def draw_impact_flash(pen, x, y, colour, core):
    points=[(8,0),(10,5),(14,2),(12,7),(16,8),(12,10),(14,14),
            (10,12),(8,16),(6,12),(2,14),(4,10),(0,8),(4,7),(2,2),(6,5)]
    pen.polygon([(x+min(px,15),y+min(py,15)) for px,py in points],fill=colour)
    pen.polygon([(x+8,y+4),(x+10,y+7),(x+13,y+8),(x+10,y+10),
                 (x+8,y+13),(x+6,y+10),(x+3,y+8),(x+6,y+7)],fill=core)
