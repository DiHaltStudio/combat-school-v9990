#!/usr/bin/env python3
"""Minimal Z80 disassembler (documented opcodes + IX/IY). usage: z80dis.py file base start end"""
import sys
R=['b','c','d','e','h','l','(hl)','a'];RP=['bc','de','hl','sp'];RP2=['bc','de','hl','af'];CC=['nz','z','nc','c','po','pe','p','m']
ALU=['add a,','adc a,','sub ','sbc a,','and ','xor ','or ','cp '];ROT=['rlc','rrc','rl','rr','sla','sra','sll','srl']
def dis(rd,pc):
    start=pc
    def n8():
        nonlocal pc; v=rd(pc); pc=(pc+1)&0xffff; return v
    def n16():
        l=n8();return l|n8()<<8
    op=n8();idx=None
    while op in(0xdd,0xfd):
        idx='ix' if op==0xdd else 'iy';op=n8()
    def rr(s):
        return s.replace('hl',idx) if idx else s
    d=None
    def r8(i):
        nonlocal d
        if not idx: return R[i]
        if i==6:
            if d is None: d=n8()
            s=d-256 if d>127 else d
            return f'({idx}{s:+d})'
        return {4:idx+'h',5:idx+'l'}.get(i,R[i])
    x,y,z=op>>6,(op>>3)&7,op&7;p,q=y>>1,y&1
    if op==0xcb:
        if idx:
            d=n8();o=n8()
            s=d-256 if d>127 else d;m=f'({idx}{s:+d})'
        else:
            o=n8();m=R[o&7]
        a,b=o>>6,(o>>3)&7
        t=[f'{ROT[b]} {m}',f'bit {b},{m}',f'res {b},{m}',f'set {b},{m}'][a]
    elif op==0xed:
        o=n8();a,b,c=o>>6,(o>>3)&7,o&7;pp,qq=b>>1,b&1
        t=f'db 0EDh,{o:02X}h'
        if a==1:
            if c==0:t=f'in {R[b]},(c)' if b!=6 else 'in (c)'
            elif c==1:t=f'out (c),{R[b]}' if b!=6 else 'out (c),0'
            elif c==2:t=('adc' if qq else 'sbc')+f' hl,{RP[pp]}'
            elif c==3:
                v=n16();t=f'ld {RP[pp]},({v:04X}h)' if qq else f'ld ({v:04X}h),{RP[pp]}'
            elif c==4:t='neg'
            elif c==5:t='reti' if b==1 else 'retn'
            elif c==6:t=f'im {[0,0,1,2,0,0,1,2][b]}'
            else:t=['ld i,a','ld r,a','ld a,i','ld a,r','rrd','rld','nop','nop'][b]
        elif a==2 and c<=3 and b>=4:
            t={(4,0):'ldi',(4,1):'cpi',(4,2):'ini',(4,3):'outi',(5,0):'ldd',(5,1):'cpd',(5,2):'ind',(5,3):'outd',(6,0):'ldir',(6,1):'cpir',(6,2):'inir',(6,3):'otir',(7,0):'lddr',(7,1):'cpdr',(7,2):'indr',(7,3):'otdr'}[(b,c)]
    elif x==0:
        if z==0:
            if y==0:t='nop'
            elif y==1:t="ex af,af'"
            else:
                e=n8();e=e-256 if e>127 else e;tg=(pc+e)&0xffff
                t={2:f'djnz {tg:04X}h',3:f'jr {tg:04X}h'}.get(y,f'jr {CC[(y-4)&3]},{tg:04X}h')
        elif z==1:
            if q==0:
                v=n16();t=f'ld {rr(RP[p])},{v:04X}h'
            else:t=f'add {rr("hl")},{rr(RP[p])}'
        elif z==2:
            if p==2:
                v=n16();t=f'ld ({v:04X}h),{rr("hl")}' if q==0 else f'ld {rr("hl")},({v:04X}h)'
            elif p==3:
                v=n16();t=f'ld ({v:04X}h),a' if q==0 else f'ld a,({v:04X}h)'
            else:
                t=f'ld ({RP[p]}),a' if q==0 else f'ld a,({RP[p]})'
        elif z==3:t=('inc ' if q==0 else 'dec ')+rr(RP[p])
        elif z==4:t='inc '+r8(y)
        elif z==5:t='dec '+r8(y)
        elif z==6:
            m=r8(y);v=n8();t=f'ld {m},{v:02X}h'
        else:t=['rlca','rrca','rla','rra','daa','cpl','scf','ccf'][y]
    elif x==1:
        if op==0x76:t='halt'
        else:
            if idx and (y==6 or z==6):
                # (ix+d) forms use plain h/l for the other operand
                if y==6:m=r8(6);t=f'ld {m},{R[z]}'
                else:m=r8(6);t=f'ld {R[y]},{m}'
            else:t=f'ld {r8(y)},{r8(z)}'
    elif x==2:t=ALU[y]+r8(z)
    else:
        if z==0:t='ret '+CC[y]
        elif z==1:
            if q==0:t='pop '+rr(RP2[p])
            else:t=['ret','exx',f'jp ({rr("hl")})',f'ld sp,{rr("hl")}'][p]
        elif z==2:
            v=n16();t=f'jp {CC[y]},{v:04X}h'
        elif z==3:
            if y==0:
                v=n16();t=f'jp {v:04X}h'
            elif y==2:t=f'out ({n8():02X}h),a'
            elif y==3:t=f'in a,({n8():02X}h)'
            else:t={4:f'ex (sp),{rr("hl")}',5:'ex de,hl',6:'di',7:'ei'}[y]
        elif z==4:
            v=n16();t=f'call {CC[y]},{v:04X}h'
        elif z==5:
            if q==0:t='push '+rr(RP2[p])
            else:
                v=n16();t=f'call {v:04X}h'
        elif z==6:
            v=n8();t=ALU[y]+f'{v:02X}h'
        else:t=f'rst {y*8:02X}h'
    return t,(pc-start)&0xffff
if __name__=='__main__':
    data=open(sys.argv[1],'rb').read();base=int(sys.argv[2],16);a=int(sys.argv[3],16);e=int(sys.argv[4],16)
    rd=lambda x:data[(x-base)] if 0<=x-base<len(data) else 0
    while a<e:
        t,l=dis(rd,a)
        print(f'{a:04X}  '+' '.join(f'{rd(a+i):02X}' for i in range(l)).ljust(12)+'  '+t);a+=l
