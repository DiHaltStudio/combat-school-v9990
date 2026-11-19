"""Pack combat poses into unused rows 212..243 of the eight scenery strips.

Two cropped copies per pose, no extra VRAM allocation or runtime uploads.
Every piece retains the arcade feet and centre anchor, including reflection.
"""
import json
from PIL import Image,ImageDraw
NAMES=('walk1','walk2','idle','raise','extend','recover','hit','fall','down')
def build_chain(a,p,ref):
    tails=[Image.new('P',(256,40),0) for _ in range(8)]
    for im in tails: im.putpalette(ref.getpalette())
    rows=[];entries=[];cache={}
    occupied=[[0]*32 for _ in range(8)]
    groups=(('chain',NAMES),('boss',('idle','walk1','walk2','walk3','windup','kick','punch','block','hurt','fall','down')))
    for group,names in groups:
      rows=[];entries=[]
      for name in names:
          original=Image.open(a/group/f'{name}.png').convert('RGBA')
          for facing in range(2):
              pose=original if facing==0 else original.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
              centre=64 if facing==0 else 63 # mirror of pixel x=64 in width 128
              pieces=[]
              for y in (0,32):
                  part=pose.crop((0,y,128,32 if y==0 else 80));box=part.getbbox()
                  if not box:
                      pieces.append([0,0,0,0,0,0]);continue
                  l,t,r,b=box;l&=~1;r=(r+1)&~1
                  crop=part.crop((l,t,r,b));w,h=crop.size
                  assert h<=32,(group,name,h)
                  indexed=crop.convert('RGB').quantize(palette=ref,dither=Image.Dither.NONE)
                  masked=Image.new('P',(w,h),0);masked.putpalette(ref.getpalette())
                  masked.paste(indexed,(0,0),crop.getchannel('A'))
                  key=(w,h,masked.tobytes())
                  if key not in cache:
                      placement=None
                      for strip in range(8):
                          for yy in range(33-h):
                              for xx in range(0,257-w,2):
                                  mask=((1<<w)-1)<<xx
                                  if all(not (occupied[strip][j]&mask) for j in range(yy,yy+h)):
                                      placement=(strip,xx,yy,mask);break
                              if placement:break
                          if placement:break
                      assert placement,'Combat poses overflow reserved scenery tails'
                      strip,x,y0,mask=placement
                      for j in range(y0,y0+h):occupied[strip][j]|=mask
                      tails[strip].paste(masked,(x,y0))
                      base=1280+256*strip if strip<4 else 3072+256*(strip-4)
                      cache[key]=(x,base+212+y0)
                  sx,sy=cache[key]
                  pieces.append([sx,sy,w,h,l-centre+32,y+t])
              entries.append(dict(name=name,facing=facing,pieces=pieces))
              for sx,sy,w,h,dx,dy in pieces:
                  rows.extend((f'        dw {sx},{sy}',f'        db {w},{h},{dx&255},{dy}'))
              bounds=[v for v in pieces if v[2]]
              left=min(v[4] for v in bounds);top=min(v[5] for v in bounds)
              right=max(v[4]+v[2] for v in bounds);bottom=max(v[5]+v[3] for v in bounds)
              rows.extend(('        dw 0,0',f'        db {right-left},{bottom-top},{left&255},{top}'))
      (p/f'{group}-descriptors.json').write_text(json.dumps(entries,indent=2))
      (p/f'{group}-poses.asm').write_text(f'mission_{group}_poses:\n'+'\n'.join(rows)+'\n')
    return tails
