import os,re,subprocess
from pathlib import Path
p=Path('build/mission/boss-test').resolve();p.mkdir(parents=True,exist_ok=True)
(p/'result.txt').unlink(missing_ok=True)
listing=Path('build/mission/visual.lst').read_text()
loop=re.search(r'00:([0-9A-F]+)\s+loop:',listing).group(1)
env=dict(os.environ,MISSION_LOOP='0x'+loop,MISSION_TEST_OUT=str(p))
subprocess.run([os.environ.get('OPENMSX', 'openmsx'),'-machine','Philips_NMS_8250','-ext','gfx9000','-cart',str(Path('build/mission/visual.rom').resolve()),'-romtype','ASCII16','-script','tools/run_demo.tcl','-script','tools/skip_mission_prelude.tcl','-script','tools/test_mission_boss.tcl'],env=env,check=True)
assert (p/'result.txt').exists()
print((p/'result.txt').read_text())
