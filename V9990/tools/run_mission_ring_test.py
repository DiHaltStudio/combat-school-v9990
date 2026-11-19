"""Run the user's reproduced load fixture against the freshly assembled ROM."""
import json, os, re, subprocess
from pathlib import Path
out=Path('build/mission/ring-test').resolve();out.mkdir(parents=True,exist_ok=True)
fixture=json.loads(Path('tools/fixtures/mission_pipe_load.json').read_text())
data=bytearray(fixture['bytes'])
for address in (0xc840,0xc852,0xc872,0xc892,0xc8c2,0xc8e2,0xc8ea,0xc912,0xc922,0xc942,0xc952,0xc962,0xc972,0xc982,0xc8a0,0xca00):
    i=address-0xc800
    value=int.from_bytes(data[i:i+2],'little')+256
    data[i:i+2]=value.to_bytes(2,'little')
# This recorded load case starts after the first thrower has been defeated.
data[0xda]=1;data[0x91]=5
state=out/'fixture.bin';state.write_bytes(data)
listing=Path('build/mission/visual.lst').read_text()
loop=re.search(r'00:([0-9A-F]+)\s+loop:',listing).group(1)
env=dict(os.environ,MISSION_TEST_OUT=str(out),MISSION_STATE=str(state),MISSION_LOOP='0x'+loop)
subprocess.run([os.environ.get('OPENMSX', 'openmsx'),'-machine',os.environ.get('MACHINE','Philips_NMS_8250'),'-ext','gfx9000','-cart',str(Path('build/mission/visual.rom').resolve()),'-romtype','ASCII16','-script','tools/run_demo.tcl','-script','tools/skip_mission_prelude.tcl','-script','tools/test_mission_ring.tcl'],env=env,check=True)
