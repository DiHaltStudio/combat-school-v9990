#!/usr/bin/env python3
"""Package the resident bank and bitmap as a 2 MiB ASCII16 ROM."""
from pathlib import Path
p=Path('build/demo')
code=(p/'bank0.bin').read_bytes()
image=(p/'image.bin').read_bytes()
assert len(code)==0x4000 and code[:2]==b'AB'
assert len(image)==27136
course=(p/'course.bin').read_bytes()
runner=(p/'runner.bin').read_bytes()
hang=(p/'hang.bin').read_bytes()
cpu=(p/'cpu.bin').read_bytes()
ui=(p/'ui.bin').read_bytes()
cpu_hang=(p/'cpu-hang.bin').read_bytes()
assert len(runner)<=0x4000 and len(hang)<=0x4000
assert len(course)==11*0x4000
# Banks 1-2 used to hold the race background; it is in the picture pack now.
rom=code
rom+=bytes([0xff])*(3*0x4000-len(rom))
rom+=course
rom+=runner+bytes([0xff])*(0x4000-len(runner))
rom+=hang+bytes([0xff])*(0x4000-len(hang))
rom+=cpu+bytes([0xff])*(0x4000-len(cpu))
rom+=ui+bytes([0xff])*(0x4000-len(ui))
rom+=cpu_hang+bytes([0xff])*(0x4000-len(cpu_hang))
assert len(rom)==19*0x4000
# Compressed full-screen pictures (tools/build_image_pack.py): race
# background, title and intro, Step 6 bonus and interlude, bonus tables and
# map, from bank 19. They took 44 banks raw.
pack=(p/'image-pack.bin').read_bytes()
assert len(pack)%0x4000==0 and len(rom)==19*0x4000
rom+=pack
assert len(rom)<=55*0x4000
rom+=bytes([0xff])*(57*0x4000-len(rom))
assert len(rom)==57*0x4000
instructor=(p/'instructor.bin').read_bytes()
assert len(instructor)==6*48*64//2
rom+=instructor+bytes([0xff])*(0x4000-len(instructor))
assert len(rom)==58*0x4000
# Banks 58-63 held the bonus tables and the map; they are in the pack now.
rom+=bytes([0xff])*(6*0x4000)
transition_bg=Path('build/step3/transition-bg.bin').read_bytes()
transition_atlas=Path('build/step3/transition-atlas.bin').read_bytes()
assert len(transition_bg)==2*0x4000 and len(transition_atlas)==0x4000
rom+=transition_bg+transition_atlas
rom+=bytes([0xff])*((74*0x4000)-len(rom))
assert len(rom)==74*0x4000
rom+=(p/'shoot-field.bin').read_bytes()
rom+=(p/'shoot-atlas.bin').read_bytes()
assert len(rom)==77*0x4000
# Integrated Step 4: code, field, atlas and recorded trajectories.
step4=Path('build/step4/integrated.rom').read_bytes()
assert len(step4)==6*0x4000 and step4[:2]==b'AB'
rom+=step4
# Banks 83-84 held the Step 4 bonus table; it is in the picture pack now.
rom+=bytes([0xff])*(2*0x4000)
step5=Path('build/step5/integrated.rom').read_bytes()
assert len(step5)==6*0x4000 and step5[:2]==b'AB'
rom+=step5
rom+=bytes([0xff])*((93*0x4000)-len(rom))
assert len(rom)==93*0x4000
rom+=(p/'shoot-poses.bin').read_bytes()
assert len(rom)==94*0x4000
seated=(p/'seated.bin').read_bytes()
assert len(seated)==2*48*48//2+4*32*64//2
rom+=seated+bytes([0xff])*(0x4000-len(seated))
assert len(rom)==95*0x4000
step3=Path('build/step3/integrated.rom').read_bytes()
assert len(step3)==32*0x4000 and step3[:2]==b'AB'
# The last four banks of the Step 3 image are unused padding. Keep their
# bank numbers available for future resources while preserving all code/data.
assert step3[28*0x4000:]==bytes([0xff])*(4*0x4000)
rom+=step3[:28*0x4000]
rom+=bytes([0xff])*(127*0x4000-len(rom))
assert len(rom)==127*0x4000
rom+=bytes([0xff])*(0x200000-len(rom))
# Fixed signature in last bank for mapper verification; no executable content.
rom=bytearray(rom)
rom[127*0x4000:127*0x4000+16]=b'COMBAT-ASCII16!!'
# Final mission (tools/build_mission_visual.py integrated): banks 34.., in
# the space freed by the picture pack; entered from the Step 7 ending.
mission=Path('build/mission/integrated.rom').read_bytes()
assert len(mission)%0x4000==0 and mission[:2]==b'AB'
mission_banks=len(mission)//0x4000
assert rom[34*0x4000:(34+mission_banks)*0x4000]==bytes([0xff])*len(mission)
rom[34*0x4000:(34+mission_banks)*0x4000]=mission
step7=Path('build/step7/integrated.rom').read_bytes()
# Code in 55, 91 and 92; the ending banks and atlas2 from 67 on.
step7_banks=(55,91,92)+tuple(range(67,67+len(step7)//0x4000-3))
assert len(step7)==len(step7_banks)*0x4000 and step7[:2]==b'AB'
for index,bank in enumerate(step7_banks):
    start=bank*0x4000
    assert rom[start:start+0x4000]==bytes([0xff])*0x4000,bank
    rom[start:start+0x4000]=step7[index*0x4000:(index+1)*0x4000]
# The fight's third atlas (moves added on 16-nov, src/step7_visual.asm
# ATLAS3_BANK, tools/build_step7_integrated.py): bank 56.
atlas3=Path('build/step7/atlas3-rle-bank.bin').read_bytes()
assert len(atlas3)==0x4000 and rom[56*0x4000:57*0x4000]==bytes([0xff])*0x4000,'bank 56 in use'
rom[56*0x4000:57*0x4000]=atlas3
# Introduction at the arcade's frame rate (tools/build_intro_anim.py): its
# pictures from bank 53.
intro=Path('build/demo/intro-anim.bin').read_bytes()
assert len(intro)%0x4000==0
assert rom[53*0x4000:53*0x4000+len(intro)]==bytes([0xff])*len(intro)
rom[53*0x4000:53*0x4000+len(intro)]=intro

# Power-on screens: DiHalt, the V9990 probe, the logo and its music
# (src/boot_logo.asm, tools/build_boot_logo.py): bank 27.
boot=Path('build/boot/boot_logo.bin').read_bytes()
assert len(boot)<=0x4000
assert rom[27*0x4000:27*0x4000+len(boot)]==bytes([0xff])*len(boot),'bank 27 in use'
rom[27*0x4000:27*0x4000+len(boot)]=boot
# The B3 opening picture uses whole rows in each bank. The build manifest
# stores one bank number followed by its 16 KiB payload.
opening=Path('build/boot/opening-banks.bin').read_bytes()
assert len(opening)%0x4001==0
opening_banks=[]
for offset in range(0,len(opening),0x4001):
    bank=opening[offset]
    start=bank*0x4000
    assert rom[start:start+0x4000]==bytes([0xff])*0x4000, f'opening bank {bank} in use'
    rom[start:start+0x4000]=opening[offset+1:offset+0x4001]
    opening_banks.append(bank)

# Arcade songs arranged for the PSG (tools/build_psg_arcade.py,
# src/psg_arcade.asm): bank 26.
arcade=Path('build/psg/arcade.bin').read_bytes()
assert len(arcade)<=0x4000
assert rom[26*0x4000:26*0x4000+len(arcade)]==bytes([0xff])*len(arcade),'bank 26 in use'
rom[26*0x4000:26*0x4000+len(arcade)]=arcade
# The mission's music as register writes (tools/build_mission_music.py,
# src/mission_boss.asm mission_music_tick): bank 26 from 9000h.
music=Path('build/psg/mission-music.bin').read_bytes()
MISSION_AT=0x1000                # 9000h: tools/build_mission_music.py
assert len(arcade)<=MISSION_AT,'the arcade songs reach the mission music'
assert MISSION_AT+len(music)<=0x4000
assert rom[26*0x4000+MISSION_AT:26*0x4000+MISSION_AT+len(music)]==bytes([0xff])*len(music),'bank 26 from 9000h in use'
rom[26*0x4000+MISSION_AT:26*0x4000+MISSION_AT+len(music)]=music

# Penalty (chin-ups, src/penalty.asm): code and its streams in banks 123-125.
penalty=Path('build/penalty/integrated.rom').read_bytes()
assert len(penalty)<=3*0x4000
penalty+=bytes([0xff])*(3*0x4000-len(penalty))
assert rom[123*0x4000:126*0x4000]==bytes([0xff])*(3*0x4000)
rom[123*0x4000:126*0x4000]=penalty
assert len(rom)==0x200000
step7_last=step7_banks[-1]
# PSG music driver (tools/build_psg_music.py, src/psg_music.asm): copied to
# RAM by init from the padding at the end of a bank, as driver.inc says.
import re
psg_inc=Path('build/psg/driver.inc').read_text()
psg_bank=int(re.search(r'PSG_ROM_BANK equ (\d+)',psg_inc).group(1))
psg_addr=int(re.search(r'PSG_ROM_ADDR equ 0x([0-9a-f]+)',psg_inc).group(1),16)
psg=Path('build/psg/driver.bin').read_bytes()
psg_start=psg_bank*0x4000+psg_addr-0x8000
assert psg_addr-0x8000+len(psg)<=0x4000
assert rom[psg_start:psg_start+len(psg)]==bytes([0xff])*len(psg),'PSG driver area in use'
rom[psg_start:psg_start+len(psg)]=psg
hats=Path('build/psg/hats.bin').read_bytes()
hats_addr=int(re.search(r'PSG_HATS_ROM equ 0x([0-9a-f]+)',psg_inc).group(1),16)
assert hats_addr==psg_addr-0x400 and len(hats)<=0x400   # src/psg_music.asm psg_install
hats_start=psg_bank*0x4000+hats_addr-0x8000
assert rom[hats_start:hats_start+len(hats)]==bytes([0xff])*len(hats),'PSG hats area in use'
rom[hats_start:hats_start+len(hats)]=hats
# Free banks: entirely FF (bank 127 holds the signature).
free=[b for b in range(127) if rom[b*0x4000:(b+1)*0x4000]==bytes([0xff])*0x4000]
free_ranges=[]
for b in free:
    if free_ranges and free_ranges[-1][1]==b-1:free_ranges[-1][1]=b
    else:free_ranges.append([b,b])
(p/'rom-layout.txt').write_text(
    'MegaROM ASCII16: 128 bancos de 16 KiB (2 MiB)\n'
    f'Step 7: bancos 55, 67-{step7_last} y 91-92.\n'
    f'Misión final: bancos 34-{33+mission_banks}.\n'
    f'Introducción: bancos 53-{52+len(intro)//0x4000}.\n'
    f'Portada tras el logo: bancos {", ".join(map(str,opening_banks))}.\n'
    f'Música del arcade para PSG: banco 26 ({len(arcade)} bytes); música de la misión desde 9000h ({len(music)} bytes).\n'
    'Revalida (dominadas): bancos 123-125.\n'
    f'Imágenes comprimidas (portada, tablas, mapa, Step 6): bancos 19-{18+len(pack)//0x4000}.\n'
    'Bancos libres para futuros recursos: '+', '.join(str(a) if a==b else f'{a}-{b}' for a,b in free_ranges)+'\n'
    f'Total libre: {sum(b-a+1 for a,b in free_ranges)} bancos = {16*sum(b-a+1 for a,b in free_ranges)} KiB\n'
    'Banco 127: firma reservada.\n')
(p/'demo-b1.rom').write_bytes(rom)
