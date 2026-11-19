.PHONY: demo rom run-demo verify-demo test-movement test-jump test-scroll

PYTHON ?= $(if $(wildcard build/venv/bin/python3),$(CURDIR)/build/venv/bin/python3,python3)

MACHINE ?= Philips_NMS_8250
OPENMSX ?= $(CURDIR)/tools/openmsx-run
export OPENMSX

DEFAULT_MAME := $(abspath ../tools/mame.sh)
MAME ?= $(DEFAULT_MAME)

.PHONY: test-step3-model
test-step3-model:
	$(PYTHON) tools/test_step3_model.py

.PHONY: test-step3-camera
test-step3-camera:
	mkdir -p build/step3
	cd src && sjasm test_step3_camera.asm ../build/step3/camera-test.rom
	STEP3_CAMERA_RESULT="$(CURDIR)/build/step3/camera-result.txt" "$(OPENMSX)" -machine $(MACHINE) -cart "$(CURDIR)/build/step3/camera-test.rom" -script tools/test_step3_camera.tcl
	$(PYTHON) -c "from pathlib import Path; assert Path('build/step3/camera-result.txt').read_text().strip() == '1'; print('OK: Z80 camera projection at visible and hidden boundaries')"

.PHONY: run-step3-visual
build-step3-visual:
	$(PYTHON) tools/build_step3_visual.py
	cd src && sjasm step3_visual.asm ../build/step3/visual.rom

run-step3-visual: build-step3-visual
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl

.PHONY: build-step3-visual test-step3-visual test-step3-obstacles test-step3-river test-step3-boats test-step3-finish test-step3-clock test-step3-restart test-step3-cpu-jump test-step3-power test-step3-mine test-step3-land test-step3-land-collisions
test-step3-visual: build-step3-visual
	STEP3_VISUAL_OUT="$(CURDIR)/build/step3/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step3_visual.tcl
	$(PYTHON) -c "from pathlib import Path; from PIL import Image; parts=Path('build/step3/visual-test/result.txt').read_text().split(); a,b,c,d=map(int,parts[:4]); assert c>a and d>b and parts[4]=='GFX9000', parts; im=Image.open('build/step3/visual-test/screen.png').convert('RGB'); assert len(im.getcolors(im.width*im.height))>8, 'game display is blank'; print('OK: V9990 selected, game visible and both runners advance',a,b,c,d)"

test-step3-obstacles: build-step3-visual
	STEP3_OBSTACLE_RESULT="$(CURDIR)/build/step3/obstacle-result.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_obstacles.tcl
	$(PYTHON) -c "from pathlib import Path; fall,jump,collision,pos=map(int,Path('build/step3/obstacle-result.txt').read_text().split()); assert fall>0 and jump>0 and collision==0 and pos>80, (fall,jump,collision,pos); print('OK: obstacle causes fall; M jumps over it')"

test-step3-mine: build-step3-visual
	STEP3_MINE_OUT="$(CURDIR)/build/step3/mine-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_mine.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,c,d=map(int,Path('build/step3/mine-test/result.txt').read_text().split()); assert a==1 and b>0 and c==0 and d>0, (a,b,c,d); print('OK: mine has debris and puddle does not')"

test-step3-land: build-step3-visual
	STEP3_LAND_OUT="$(CURDIR)/build/step3/land-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_land.tcl
	$(PYTHON) tools/check_step3_land.py

test-step3-land-collisions: build-step3-visual
	STEP3_LAND_COLLISION_RESULT="$(CURDIR)/build/step3/land-collisions.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_land_collisions.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,c,d,e,f,g=map(int,Path('build/step3/land-collisions.txt').read_text().split()); assert a>0 and b==0 and c>0 and d==1 and e==0 and f>184 and g>0, (a,b,c,d,e,f,g); print('OK: puddle, mine, rock and lateral avoidance on shared land course')"

test-step3-river: build-step3-visual
	mkdir -p build/step3/river-test
	STEP3_RIVER_OUT="$(CURDIR)/build/step3/river-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_river.tcl
	$(PYTHON) -c "from pathlib import Path; from PIL import Image; a,b,c,d=map(int,Path('build/step3/river-test/result.txt').read_text().split()); im=Image.open('build/step3/river-test/river.png').convert('RGB'); r,g,bl=im.getpixel((50,40)); assert a>0 and b==0 and c==d==8 and g>r*2 and bl>r*2, (a,b,c,d,r,g,bl); print('OK: contact, river display and no jumping while swimming')"

test-step3-boats: build-step3-visual
	STEP3_BOAT_RESULT="$(CURDIR)/build/step3/boat-result.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_boats.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,c,d,e,f,g,*debug=map(int,Path('build/step3/boat-result.txt').read_text().split()); assert a==1 and b==3 and c>0 and d==0 and e==1 and f==2 and g>0, (a,b,c,d,e,f,g,debug); print('OK: boat pickup, log collision and handover')"

test-step3-finish: build-step3-visual
	for winner in player cpu; do STEP3_WINNER=$$winner STEP3_FINISH_RESULT="$(CURDIR)/build/step3/finish-$$winner.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_finish.tcl || exit 1; done
	$(PYTHON) -c "from pathlib import Path; read=lambda n:list(map(int,Path('build/step3/finish-'+n+'.txt').read_text().split())); p,c=read('player'),read('cpu'); assert p[:6]==[1,1,0,1,1,1] and c[:6]==[2,0,1,2,1,1] and p[6]!=p[7] and c[6]!=c[7] and p[8]==p[9] and p[10]==min(5,p[8]//2) and c[10]==min(5,c[9]//2), (p,c); print('OK: finishes, preserved time/bonus and moving logs')"

test-step3-clock: build-step3-visual
	STEP3_CLOCK_RESULT="$(CURDIR)/build/step3/clock-result.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_clock.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,c,d,e,f,g=map(int,Path('build/step3/clock-result.txt').read_text().split()); assert 1<=a-b<=2 and (c,d,e,f,g)==(0,1,3,1,1), (a,b,c,d,e,f,g); print('OK: countdown and timeout')"

test-step3-restart: build-step3-visual
	STEP3_RESTART_OUT="$(CURDIR)/build/step3/restart-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_restart.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,sec,c,d,e,f,g=map(int,Path('build/step3/restart-test/result.txt').read_text().split()); assert a==min(5,sec//2) and b==[0,1000,2000,4000,6000,8000][a] and (c,d,e,g)==(0,0,0,0) and 40<=f<=45, (a,b,sec,c,d,e,f,g); print('OK: bonus and restart')"

test-step3-cpu-jump: build-step3-visual
	STEP3_CPU_JUMP_RESULT="$(CURDIR)/build/step3/cpu-jump.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_cpu_jump.tcl
	$(PYTHON) -c "from pathlib import Path; jump,pos,stun=map(int,Path('build/step3/cpu-jump.txt').read_text().split()); assert jump==1 and pos>720 and stun==0, (jump,pos,stun); print('OK: CPU jumps over obstacle')"

test-step3-power: build-step3-visual
	STEP3_POWER_OUT="$(CURDIR)/build/step3/power-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_power.tcl
	$(PYTHON) -c "from pathlib import Path; from PIL import Image; a,b=map(int,Path('build/step3/power-test/result.txt').read_text().split()); im=Image.open('build/step3/power-test/power.png').convert('RGB'); red=sum(r>180 and g<60 and b<60 for r,g,b in im.crop((70,186,138,199)).getdata()); assert b>a and red>5, (a,b,red); print('OK: repeated presses increase visible POWER',a,b,red)"

.PHONY: demo-assets
demo:
	python3 ../tools/prepare-mame-captures.py
ifeq ($(MAME),$(DEFAULT_MAME))
	@test -x ../build/mame-source/combatschool || ../tools/build-mame.sh
endif
	$(MAKE) demo-assets

demo-assets: build/mame-trace/frame-1200/registers.txt
demo-assets: build/ironman/land.bin build/ironman/collision.bin build/ironman/surfaces.bin
demo-assets: assets/runner/seated-player.png assets/runner/seated-cpu.png build/cpu-reference/2280.png
demo-assets: build/instructor/804.png build/instructor/876.png build/instructor/888.png build/instructor/2280.png build/mame-intro/combatsc/0043.png build/cpu-reference/1155.png build/cpu-reference/1215.png build/cpu-reference/1080.png build/cpu-reference/1095.png build/cpu-reference/1110.png build/cpu-reference/1845.png build/cpu-reference/1770.png build/cpu-reference/1815.png build/cpu-reference/1785.png build/cpu-reference/1830.png build/cpu-reference/1755.png build/course-analysis/course-reconstruction.png build/course-analysis/course-finished.png build/goal/player-raised.png build/mame-shoot/frame-5936/registers.txt build/runner-run/1102.png build/runner-run/1108.png build/runner-run/1116.png build/runner-run/1128.png build/runner-jump/1102.png build/runner-bars/2295.png build/runner-bars/2430.png build/runner-bars/1380.png build/runner-bars/1410.png build/runner-bars/1605.png build/runner-bars/1620.png build/runner-vault/1714.png build/runner-vault/1736.png build/runner-vault/1742.png build/runner-vault/1748.png build/runner-vault/1754.png build/runner-bars-dense/2300.png build/runner-bars-dense/2304.png build/runner-bars-dense/2308.png build/runner-bars-dense/2320.png build/runner-bars-dense/2324.png build/runner-bars-dense/2330.png
	$(PYTHON) tools/render_background.py build/mame-trace/frame-1200 --vreg 0x33
	$(PYTHON) tools/build_psg_music.py E000 build/psg
	$(PYTHON) tools/build_psg_arcade.py
	$(PYTHON) tools/build_mission_music.py
	$(PYTHON) tools/build_demo_assets.py
	$(PYTHON) tools/build_intro_assets.py
	$(PYTHON) tools/build_progress_assets.py
	$(PYTHON) tools/build_step6_interlude.py
	$(PYTHON) tools/build_shoot_assets.py
	$(PYTHON) tools/build_step3_visual.py
	$(PYTHON) tools/build_step3_transition.py
	$(PYTHON) tools/build_step4_visual.py
	$(PYTHON) tools/build_step4_integrated.py
	$(PYTHON) tools/build_step5_assets.py
	$(PYTHON) tools/build_step5_integrated.py
	$(PYTHON) tools/build_step7_visual.py
	$(PYTHON) tools/build_step7_ending.py
	$(PYTHON) tools/build_step7_integrated.py
	$(PYTHON) tools/build_image_pack.py
	cd src && sjasm ../build/step7/integrated.asm ../build/step7/integrated.rom
	cd src && sjasm ../build/step5/integrated.asm ../build/step5/integrated.rom
	cd src && sjasm ../build/step4/integrated.asm ../build/step4/integrated.rom
	$(PYTHON) tools/build_step3_integrated.py
	cd src && sjasm ../build/step3/step3_integrated.asm ../build/step3/integrated.rom
	$(PYTHON) tools/build_mission_visual.py integrated
	cd src && sjasm ../build/mission/integrated.asm ../build/mission/integrated.rom
	$(PYTHON) tools/build_intro_anim.py
	$(PYTHON) tools/build_boot_logo.py
	cd src && sjasm boot_logo.asm ../build/boot/boot_logo.bin
	cd src && sjasm demo_b1.asm ../build/demo/bank0.bin
	$(MAKE) --no-print-directory build-penalty-visual
	$(PYTHON) tools/build_megarom.py

rom: demo
	cp build/demo/demo-b1.rom CombatSchool-V9990.rom

build/mame-trace/frame-1200/registers.txt: tools/mame_capture.lua tools/mame_capture_common.lua
	mkdir -p build/mame-trace
	rm -f build/mame-trace/combatsc/*.png
	COMBAT_DUMP="$(CURDIR)/build/mame-trace" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-trace" -autoboot_script tools/mame_capture.lua

build/mame-intro/combatsc/0043.png: tools/mame_intro_capture.lua
	mkdir -p build/mame-intro
	rm -f build/mame-intro/combatsc/*.png
	SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-intro" -autoboot_script tools/mame_intro_capture.lua
	touch $@

build/instructor/804.png build/instructor/876.png build/instructor/888.png build/instructor/2280.png &: tools/mame_instructor_capture.lua tools/mame_capture_common.lua tools/extract_instructor.py
	mkdir -p build/mame-instructor
	rm -f build/mame-instructor/combatsc/*.png
	COMBAT_DUMP="$(CURDIR)/build/mame-instructor" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-instructor" -autoboot_script tools/mame_instructor_capture.lua
	$(PYTHON) tools/extract_instructor.py

build/mame-course-state/frame-2700/registers.txt: tools/mame_course_state.lua tools/mame_capture_common.lua
	mkdir -p build/mame-course-state
	rm -f build/mame-course-state/combatsc/*.png
	COMBAT_DUMP="$(CURDIR)/build/mame-course-state" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-course-state" -autoboot_script tools/mame_course_state.lua

build/course-analysis/course-reconstruction.png: build/mame-course-state/frame-2700/registers.txt tools/analyze_course_layers.py tools/render_background.py tools/map_course.py
	COURSE_STRIDE=1 $(PYTHON) tools/analyze_course_layers.py
	$(PYTHON) tools/map_course.py

# Same inputs as the course capture, continued until the player reaches the
# goal: bars exit, goal scenery and the goal poses. A second short run keeps
# the player's bars entry.
build/mame-finish/frame-3036/registers.txt: tools/mame_finish_capture.lua tools/mame_capture_common.lua
	rm -rf build/mame-finish && mkdir -p build/mame-finish
	COMBAT_DUMP="$(CURDIR)/build/mame-finish" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-finish" -autoboot_script tools/mame_finish_capture.lua

build/mame-bars-entry/frame-2236/registers.txt: tools/mame_finish_capture.lua tools/mame_capture_common.lua
	rm -rf build/mame-bars-entry && mkdir -p build/mame-bars-entry
	FINISH_FIRST=2140 FINISH_LAST=2340 FINISH_STEP=8 COMBAT_DUMP="$(CURDIR)/build/mame-bars-entry" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-bars-entry" -autoboot_script tools/mame_finish_capture.lua

build/course-analysis/course-finished.png: build/course-analysis/course-reconstruction.png build/mame-finish/frame-3036/registers.txt build/mame-bars-entry/frame-2236/registers.txt tools/build_course_finish.py tools/render_background.py
	$(PYTHON) tools/build_course_finish.py

# First firing range played by an aiming bot until it qualifies: arcade
# targets and the shooter standing up and raising his arm (extract_shoot_goal.py).
build/mame-shoot/frame-5936/registers.txt: tools/mame_shoot_capture.lua tools/mame_capture_common.lua
	rm -rf build/mame-shoot && mkdir -p build/mame-shoot
	COMBAT_DUMP="$(CURDIR)/build/mame-shoot" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-shoot" -autoboot_script tools/mame_shoot_capture.lua

# The explosion on a hit target (Steps 2 and 6): every frame of the first
# hits of the same bot run (tools/extract_target_explosion.py).
.PHONY: capture-shoot-hit
capture-shoot-hit:
	rm -rf build/mame-shoot-hit && mkdir -p build/mame-shoot-hit
	COMBAT_DUMP="$(CURDIR)/build/mame-shoot-hit" SHOOT_FIRST=3625 SHOOT_LAST=3760 SHOOT_STEP=1 SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-shoot-hit" -autoboot_script tools/mame_shoot_capture.lua
	PYTHONPATH=tools $(PYTHON) tools/extract_target_explosion.py

build/goal/player-raised.png: build/mame-finish/frame-3036/registers.txt tools/extract_goal_poses.py tools/arcade_sprites.py
	$(PYTHON) tools/extract_goal_poses.py

build/runner-run/1102.png build/runner-run/1108.png build/runner-run/1116.png build/runner-run/1128.png &: tools/mame_animation_capture.lua tools/mame_capture_common.lua tools/extract_runner_frames.py
	mkdir -p build/mame-button1
	rm -f build/mame-button1/combatsc/*.png
	COMBAT_INPUT=button1 COMBAT_DUMP="$(CURDIR)/build/mame-button1" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-button1" -autoboot_script tools/mame_animation_capture.lua
	$(PYTHON) tools/extract_runner_frames.py

build/runner-jump/1102.png: tools/mame_animation_capture.lua tools/mame_capture_common.lua tools/extract_runner_frames.py
	mkdir -p build/mame-button2
	rm -f build/mame-button2/combatsc/*.png
	COMBAT_INPUT=button2 COMBAT_DUMP="$(CURDIR)/build/mame-button2" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-button2" -autoboot_script tools/mame_animation_capture.lua
	$(PYTHON) tools/extract_runner_frames.py build/mame-button2 build/runner-jump

build/runner-bars/2295.png build/runner-bars/2430.png build/runner-bars/1380.png build/runner-bars/1410.png build/runner-bars/1605.png build/runner-bars/1620.png &: build/course-analysis/course-reconstruction.png tools/extract_runner_frames.py
	$(PYTHON) tools/extract_runner_frames.py build/mame-course-state build/runner-bars

build/runner-bars-dense/2300.png build/runner-bars-dense/2304.png build/runner-bars-dense/2308.png build/runner-bars-dense/2320.png build/runner-bars-dense/2324.png build/runner-bars-dense/2330.png &: tools/mame_bars_capture.lua tools/mame_capture_common.lua tools/extract_runner_frames.py
	mkdir -p build/mame-bars
	rm -f build/mame-bars/combatsc/*.png
	COMBAT_DUMP="$(CURDIR)/build/mame-bars" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-bars" -autoboot_script tools/mame_bars_capture.lua
	$(PYTHON) tools/extract_runner_frames.py build/mame-bars build/runner-bars-dense

build/cpu-reference/1155.png build/cpu-reference/1215.png build/cpu-reference/1080.png build/cpu-reference/1095.png build/cpu-reference/1110.png build/cpu-reference/2280.png build/cpu-reference/1845.png build/cpu-reference/1770.png build/cpu-reference/1815.png build/cpu-reference/1785.png build/cpu-reference/1830.png build/cpu-reference/1755.png &: build/course-analysis/course-reconstruction.png tools/extract_cpu_frames.py
	$(PYTHON) tools/extract_cpu_frames.py

build/runner-vault/1714.png build/runner-vault/1736.png build/runner-vault/1742.png build/runner-vault/1748.png build/runner-vault/1754.png &: tools/mame_vault_capture.lua tools/mame_capture_common.lua tools/extract_runner_frames.py
	mkdir -p build/mame-vault
	rm -f build/mame-vault/combatsc/*.png
	COMBAT_DUMP="$(CURDIR)/build/mame-vault" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-vault" -autoboot_script tools/mame_vault_capture.lua
	$(PYTHON) tools/extract_runner_frames.py build/mame-vault build/runner-vault

.PHONY: run
build/mame-ironman/frame-9200/registers.txt: tools/mame_ironman_capture.lua tools/mame_capture_common.lua
	rm -rf build/mame-ironman
	mkdir -p build/mame-ironman
	COMBAT_DUMP="$(CURDIR)/build/mame-ironman" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-ironman" -autoboot_script tools/mame_ironman_capture.lua

build/ironman/course-index.npy: build/mame-ironman/frame-9200/registers.txt tools/stitch_ironman.py
	$(PYTHON) tools/stitch_ironman.py

build/ironman/land.bin build/ironman/collision.bin build/ironman/surfaces.bin &: build/ironman/course-index.npy tools/build_ironman_course.py
	$(PYTHON) tools/build_ironman_course.py

build-step3-visual: build/ironman/land.bin build/ironman/collision.bin build/ironman/surfaces.bin

RELEASE_ROM := $(abspath ../release/CombatSchool-V9990.rom)
RUN_ROM := $(if $(wildcard $(RELEASE_ROM)),$(RELEASE_ROM),$(CURDIR)/CombatSchool-V9990.rom)
RUN_ROM_DEP := $(if $(wildcard $(RELEASE_ROM)),,rom)

run: $(RUN_ROM_DEP)
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(RUN_ROM)" -romtype ASCII16 -script tools/run_demo.tcl

run-demo: run

.PHONY: run-shoot
run-shoot: $(RUN_ROM_DEP)
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(RUN_ROM)" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_skip_intro.tcl -script tools/run_shoot.tcl

.PHONY: run-mission
run-mission: $(RUN_ROM_DEP)
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(RUN_ROM)" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_boot.tcl -script tools/run_mission.tcl

.PHONY: run-msx-flag
run-msx-flag: $(RUN_ROM_DEP)
	PREVIEW_MSX_FLAG=1 "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(RUN_ROM)" -romtype ASCII16 -script tools/run_demo.tcl -script tools/run_mission.tcl

.PHONY: run-step7
run-step7: $(RUN_ROM_DEP)
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(RUN_ROM)" -romtype ASCII16 -script tools/run_demo.tcl -script tools/run_step7.tcl

.PHONY: test-mission-integrated test-mission-integrated-ending
test-mission-integrated: demo
	PRELUDE_ATTENTION=$$(printf %d 0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+prelude_attention:)' build/mission/integrated.lst)) PRELUDE_MANSION=$$(printf %d 0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+prelude_mansion:)' build/mission/integrated.lst)) MISSION_INTEGRATED_OUT="$(CURDIR)/build/mission/integrated-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_skip_intro.tcl -script tools/test_mission_integrated.tcl
	$(PYTHON) tools/check_mission_integrated.py

test-mission-integrated-ending: demo
	PRELUDE_ATTENTION=$$(printf %d 0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+prelude_attention:)' build/mission/integrated.lst)) PRELUDE_MANSION=$$(printf %d 0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+prelude_mansion:)' build/mission/integrated.lst)) MISSION_ENDING=1 MISSION_INTEGRATED_OUT="$(CURDIR)/build/mission/integrated-ending-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_skip_intro.tcl -script tools/test_mission_integrated.tcl
	$(PYTHON) tools/check_mission_integrated.py build/mission/integrated-ending-test

.PHONY: test-intro
test-intro: demo
	PRELUDE_INTRO=$$(printf %d 0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+prelude_intro:)' build/demo/bank0.lst)) INTRO_OUT="$(CURDIR)/build/demo/intro-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/skip_boot.tcl -script tools/test_intro.tcl
	$(PYTHON) tools/check_intro.py

.PHONY: test-boot-video
test-boot-video: demo
	VIDEO_OUT="$(CURDIR)/build/demo/boot-video.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_boot.tcl -script tools/test_boot_video.tcl
	$(PYTHON) -c "from pathlib import Path; boot,title,state=Path('build/demo/boot-video.txt').read_text().split(); assert (boot,title,state)==('MSX','GFX9000','1'); print('OK: MSX boot screen precedes V9990 title')"

.PHONY: test-instructor
test-instructor: demo
	INSTRUCTOR_OUT="$(CURDIR)/build/demo/instructor-trace.txt" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_instructor.tcl
	$(PYTHON) tools/check_instructor.py

.PHONY: test-progress
test-progress: demo
	for remaining in 0 1 2 3 4 5 6 7 8 9 10 12; do for cpu in 0 1; do REMAINING=$$remaining CPU_FIRST=$$cpu PROGRESS_OUT="$(CURDIR)/build/demo/progress-$$remaining-$$cpu" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_progress.tcl || exit 1; $(PYTHON) tools/check_progress.py "build/demo/progress-$$remaining-$$cpu" $$remaining $$cpu || exit 1; done; done

.PHONY: test-shoot
test-shoot: demo
	SHOOT_OUT="$(CURDIR)/build/demo/shoot-test" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_shoot.tcl
	$(PYTHON) tools/check_shoot.py
	for hits in 43 44 47 48 51 52 55 56 59 60 67 68; do SHOOT_HITS=$$hits SHOOT_RESULT="$(CURDIR)/build/demo/shoot-result.txt" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_shoot_result.tcl || exit 1; $(PYTHON) tools/check_shoot_result.py $$hits || exit 1; done
	SHOOT_RESULT="$(CURDIR)/build/demo/shoot-44.txt" SHOOT_WAVES="$(CURDIR)/build/demo/shoot-waves.txt" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_shoot_44.tcl
	$(PYTHON) -c "from pathlib import Path; hits,targets,time,state=map(int,Path('build/demo/shoot-44.txt').read_text().split()); assert hits==44 and targets>0 and time>0 and state==1; print('OK: 44 hits register and play continues')"
	$(PYTHON) -c "from pathlib import Path; a=[list(map(int,l.split())) for l in Path('build/demo/shoot-waves.txt').read_text().splitlines()]; assert {3,7,15}.issubset({r[0] for r in a}) and len({r[1] for r in a})>1 and all([r[i+1]-r[i] for i in range(1,4)]==[24,24,24] for r in a); print('OK: varied adjacent target groups')"
	SHOOT_OUT="$(CURDIR)/build/demo/shoot-hud" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_shoot_hud.tcl
	$(PYTHON) tools/check_shoot_hud.py
	for hits in 44 52 68; do SHOOT_HITS=$$hits SHOOT_PROGRESS_OUT="$(CURDIR)/build/demo/shoot-progress-$$hits" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_shoot_progress.tcl || exit 1; $(PYTHON) tools/check_shoot_progress.py "build/demo/shoot-progress-$$hits" $$hits || exit 1; done
	SHOOT_POSES_OUT="$(CURDIR)/build/demo/shoot-poses-test" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_shoot_poses.tcl
	$(PYTHON) tools/check_shoot_poses.py

.PHONY: test-shared-track
test-shared-track: demo
	for pair in 300:0 292:-8 550:250 800:500 44:-256; do scroll=$${pair%:*}; x=$${pair#*:}; PEER_SCROLL=$$scroll DV_OUT="$(CURDIR)/build/demo/peer-$$scroll" DV_SECONDS=12.4 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_peer_view.tcl -script tools/dump_v9990.tcl || exit 1; $(PYTHON) tools/verify_demo.py "build/demo/peer-$$scroll" || exit 1; $(PYTHON) tools/check_peer_view.py "build/demo/peer-$$scroll" $$x || exit 1; done
	DV_OUT="$(CURDIR)/build/demo/shared-bars" DV_SECONDS=12.2 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_shared_bars.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/shared-bars
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/shared-bars/ram.bin').read_bytes(); assert r[0xc033]==9 and r[0xc0a3]==10 and r[0xc0fd]==0; print('OK: both hanging runners appear in both cameras')"
	for scenario in player_passes cpu_passes different_height; do OVERTAKE_CASE=$$scenario OVERTAKE_OUT="$(CURDIR)/build/demo/overtake-$$scenario.txt" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_bars_overtake.tcl || exit 1; $(PYTHON) tools/check_bars_overtake.py $$scenario "build/demo/overtake-$$scenario.txt" || exit 1; done
	for scenario in player_passes cpu_passes; do OVERTAKE_CASE=$$scenario OVERTAKE_OUT="$(CURDIR)/build/demo/overtake-display-$$scenario.txt" DV_OUT="$(CURDIR)/build/demo/overtake-display-$$scenario" DV_SECONDS=12.8 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_bars_overtake.tcl -script tools/dump_v9990.tcl || exit 1; $(PYTHON) tools/verify_demo.py "build/demo/overtake-display-$$scenario" || exit 1; done

verify-demo: demo
	DV_OUT="$(CURDIR)/build/demo/dump" DV_SECONDS=15 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py

# Hold right for one emulated second and verify the resulting image.
test-movement: demo
	DV_OUT="$(CURDIR)/build/demo/moved" DV_SECONDS=15 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_movement.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/moved
	$(PYTHON) -c "from pathlib import Path; x=Path('build/demo/moved/ram.bin').read_bytes()[0xc000]; assert x > 64, f'unexpected x={x}'"

test-jump: demo
	DV_OUT="$(CURDIR)/build/demo/jump" DV_SECONDS=12.4 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_jump_move.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/jump
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/jump/ram.bin').read_bytes(); assert r[0xc000] > 64 and r[0xc005] < 55 and r[0xc030] == 128"
	DV_OUT="$(CURDIR)/build/demo/landed" DV_SECONDS=15 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_jump_move.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/landed
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/landed/ram.bin').read_bytes(); assert r[0xc005] == 55 and r[0xc003] == 0"

test-scroll: demo
	DV_OUT="$(CURDIR)/build/demo/scroll" DV_SECONDS=20 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_scroll.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/scroll
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/scroll/ram.bin').read_bytes(); assert r[0xc000] == 100 and 160 <= r[0xc006] <= 200 and r[0xc00c] == 0"

.PHONY: test-run-inputs
test-run-inputs: demo
	for scenario in fast slow held; do RUN_TEST=$$scenario DV_OUT="$(CURDIR)/build/demo/run-$$scenario" DV_SECONDS=14 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_run_inputs.tcl -script tools/dump_v9990.tcl || exit 1; $(PYTHON) tools/verify_demo.py build/demo/run-$$scenario || exit 1; done
	$(PYTHON) -c "from pathlib import Path; get=lambda n: Path('build/demo/run-'+n+'/ram.bin').read_bytes(); f,s,h=map(get,('fast','slow','held')); pos=lambda r: r[0xc000]+r[0xc006]+256*r[0xc00c]; assert pos(f) > max(100,pos(s)) and pos(s) > pos(h) == 64 and h[0xc00b] > 0"

.PHONY: test-animation
test-animation: demo
	ANIM_LOG="$(CURDIR)/build/demo/animation.csv" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_movement.tcl -script tools/test_animation.tcl
	$(PYTHON) -c "from pathlib import Path; rows=[list(map(float,l.split())) for l in Path('build/demo/animation.csv').read_text().splitlines()]; active=[r for r in rows if r[3]>0]; assert {32,64,96}.issubset({int(r[4]) for r in active}); assert any(a[1]==b[1] and a[4] in (32,64,96) and b[4] in (32,64,96) for a,b in zip(active,active[1:])); print('OK: animation advances during running even between movement steps')"

.PHONY: test-mapper
test-mapper: demo
	rm -f build/demo/mapper-result.txt
	MAPPER_RESULT="$(CURDIR)/build/demo/mapper-result.txt" timeout 30s "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_mapper.tcl
	cat build/demo/mapper-result.txt

.PHONY: test-rewind
test-rewind: demo
	REWIND_RESULT="$(CURDIR)/build/demo/rewind-result.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/skip_boot.tcl -script tools/test_rewind.tcl
	$(PYTHON) -c "from pathlib import Path; lines=Path('build/demo/rewind-result.txt').read_text().splitlines(); status,before,back,forward=lines[0].split(); before,back,forward=map(float,(before,back,forward)); assert status=='enabled' and back < before and forward > back and abs(forward-before)<0.1 and all(cmd in line for cmd,line in zip(('go_back_one_step','go_forward_one_step','go_back_one_step','go_forward_one_step'),lines[1:5])),lines; print('OK: Page Up/Down and numeric keypad 9/3 bindings; history moves in both directions')"

.PHONY: test-course-end
test-course-end: demo
	DV_OUT="$(CURDIR)/build/demo/finish" DV_SECONDS=16 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_course_end.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/finish
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/finish/ram.bin').read_bytes(); assert r[0xc006]+256*r[0xc00c] == 2488; assert (r[0xc0d5],r[0xc003],r[0xc005],r[0xc036]) == (1,0,55,39); assert (r[0xc094],r[0xc093],r[0xc0a6]) == (0,159,159); print('OK: both runners are grounded at the result after jumping across the line')"

.PHONY: test-obstacles
test-obstacles: demo
	DV_OUT="$(CURDIR)/build/demo/wall-jump" DV_SECONDS=16 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_wall_jump.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/wall-jump
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/wall-jump/ram.bin').read_bytes(); assert r[0xc006]+r[0xc00c]*256 > 222 and r[0xc005]==55"
	DV_OUT="$(CURDIR)/build/demo/hang-rest" DV_SECONDS=16 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_hang.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/hang-rest
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/hang-rest/ram.bin').read_bytes(); assert r[0xc00a]==1 and r[0xc005]==24 and r[0xc006]+r[0xc00c]*256 > 1918"
	DV_OUT="$(CURDIR)/build/demo/climb" DV_SECONDS=12.4 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_tall_wall.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/climb
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/climb/ram.bin').read_bytes(); assert r[0xc087]==1 and r[0xc032]+256*r[0xc033]==664"
	DV_OUT="$(CURDIR)/build/demo/tall" DV_SECONDS=16 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_tall_wall.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/tall
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/tall/ram.bin').read_bytes(); assert r[0xc006]+r[0xc00c]*256 > 1020"
	DV_OUT="$(CURDIR)/build/demo/hang-end" DV_SECONDS=16 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_hang_end.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/hang-end
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/hang-end/ram.bin').read_bytes(); assert r[0xc00a]==0 and r[0xc005]==55 and r[0xc0d9] in (0,1) and r[0xc006]+256*r[0xc00c]>2314"

.PHONY: test-collision
test-collision: demo
	DV_OUT="$(CURDIR)/build/demo/impact" DV_SECONDS=12.8 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_wall_impact.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/impact
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/impact/ram.bin').read_bytes(); assert r[0xc006] == 190 and r[0xc086]>0 and r[0xc032]+256*r[0xc033]==600"
	WALL_TRACE="$(CURDIR)/build/demo/wall-trace.txt" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_wall_jump.tcl -script tools/test_wall_trace.tcl
	$(PYTHON) -c "from pathlib import Path; rows=[list(map(float,l.split())) for l in Path('build/demo/wall-trace.txt').read_text().splitlines()]; rows=[r for r in rows if r[0]<13.3]; inside=[r for r in rows if r[5]==1]; assert inside and max(r[4] for r in inside)<=39 and not any(r[6]>0 for r in rows); print('OK: jump clears wall and feet stay above it until fully past')"

.PHONY: test-vault-impact
test-vault-impact: demo
	DV_OUT="$(CURDIR)/build/demo/stand-vault" DV_SECONDS=16 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_stand_jump.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/stand-vault
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/stand-vault/ram.bin').read_bytes(); assert r[0xc006]+256*r[0xc00c]>=242 and r[0xc088]==0 and r[0xc086]==0"
	DV_OUT="$(CURDIR)/build/demo/auto" DV_SECONDS=16 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_vault_auto.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/auto
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/auto/ram.bin').read_bytes(); assert r[0xc006]+256*r[0xc00c]>=242 and r[0xc088]==0 and r[0xc086]==0"
	for speed in 12 24 48; do IMPACT_SPEED=$$speed DV_OUT="$(CURDIR)/build/demo/impact-$$speed" DV_SECONDS=12.25 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_impact_speeds.tcl -script tools/dump_v9990.tcl || exit 1; $(PYTHON) tools/verify_demo.py build/demo/impact-$$speed || exit 1; done
	$(PYTHON) -c "from pathlib import Path; get=lambda n:Path('build/demo/impact-'+str(n)+'/ram.bin').read_bytes(); a,b,c=map(get,(12,24,48)); assert a[0xc086]==0 and a[0xc006]==190 and b[0xc086]>0 and b[0xc08a]==0 and c[0xc086]>0 and c[0xc08a]==1 and c[0xc006]<190; print('OK: low-speed stop, forward fall and fast recoil')"

.PHONY: test-wall-types
.PHONY: test-bars-entry
test-bars-entry: demo
	DV_OUT="$(CURDIR)/build/demo/bars-block" DV_SECONDS=19 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_bars_entry.tcl -script tools/dump_v9990.tcl
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/bars-block/ram.bin').read_bytes(); c=r[0xc006]+256*r[0xc00c]+r[0xc000]+16; assert c==2032 and r[0xc00a]==0 and r[0xc005]==55 and r[0xc086]==0 and r[0xc008]>0, (c,r[0xc00a],r[0xc005],r[0xc086],r[0xc008]); print('OK: without a jump the runner stays at the front post of the bars')"
	BARS_JUMP=1 DV_OUT="$(CURDIR)/build/demo/bars-cross" DV_SECONDS=24 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_bars_entry.tcl -script tools/dump_v9990.tcl
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/bars-cross/ram.bin').read_bytes(); c=r[0xc006]+256*r[0xc00c]+r[0xc000]+16; assert c>2430, c; print('OK: a jump at the post grabs the bars and crosses them')"

test-wall-types: demo
	for wall in 190 478; do IMPACT_SPEED=24 IMPACT_SCROLL=$$wall DV_OUT="$(CURDIR)/build/demo/wall-$$wall" DV_SECONDS=12.25 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_impact_speeds.tcl -script tools/dump_v9990.tcl || exit 1; $(PYTHON) tools/verify_demo.py build/demo/wall-$$wall || exit 1; done
	$(PYTHON) -c "from pathlib import Path; get=lambda n:Path('build/demo/wall-'+str(n)+'/ram.bin').read_bytes(); a,b=map(get,(190,478)); assert a[0xc086]>0 and a[0xc08a]==0 and a[0xc006]==190 and b[0xc086]>0 and b[0xc08a]==1 and b[0xc006]+256*b[0xc00c]<478; print('OK: low wall falls forward, medium wall recoils')"
	DV_OUT="$(CURDIR)/build/demo/hand" DV_SECONDS=12.43 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_hand_vault.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/hand
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/hand/ram.bin').read_bytes(); assert r[0xc087]==1 and r[0xc032]+256*r[0xc033]==664"
	DV_OUT="$(CURDIR)/build/demo/hand-end" DV_SECONDS=16 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_hand_vault.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/hand-end
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/hand-end/ram.bin').read_bytes(); assert r[0xc006]+256*r[0xc00c]>=530 and r[0xc087]==0 and r[0xc086]==0"

.PHONY: test-hang-animation
test-hang-animation: demo
	ANIM_LOG="$(CURDIR)/build/demo/hang-animation.txt" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_hang.tcl -script tools/test_hang_animation.tcl
	$(PYTHON) -c "from pathlib import Path; rows=[list(map(int,l.split())) for l in Path('build/demo/hang-animation.txt').read_text().splitlines()]; seen={(r[1],r[2]+256*r[3]) for r in rows if r[0]==1}; assert {(0,2304),(48,2304),(96,2304),(144,2304),(192,2304),(0,2368)} <= seen; print('OK: six hanging poses shown')"

.PHONY: test-race
test-race: demo
	RACE_LOG="$(CURDIR)/build/demo/cpu-race.log" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_cpu_race.tcl
	$(PYTHON) tools/check_cpu_race.py
	for scenario in player cpu timeout; do RESULT_TEST=$$scenario DV_OUT="$(CURDIR)/build/demo/result-$$scenario" DV_SECONDS=16 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_result.tcl -script tools/dump_v9990.tcl || exit 1; $(PYTHON) tools/verify_demo.py build/demo/result-$$scenario || exit 1; done
	$(PYTHON) -c "from pathlib import Path; get=lambda n:Path('build/demo/result-'+n+'/ram.bin').read_bytes(); p,c,t=map(get,('player','cpu','timeout')); assert p[0xc0d9]==1 and c[0xc0d9]==2 and t[0xc0d9]==3 and p[0xc0bb]&1 and c[0xc0bb]&2; print('OK: player and CPU wins with instructor, and timeout')"
	DV_OUT="$(CURDIR)/build/demo/restarted" DV_SECONDS=50 "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_restart.tcl -script tools/dump_v9990.tcl
	$(PYTHON) tools/verify_demo.py build/demo/restarted
	$(PYTHON) -c "from pathlib import Path; r=Path('build/demo/restarted/ram.bin').read_bytes(); assert r[0xc0d9]==0 and r[0xc000]==64; print('OK: race restarts')"
	CLOCK_OUT="$(CURDIR)/build/demo/clock.txt" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_clock.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,h=map(int,Path('build/demo/clock.txt').read_text().split()); assert a-b==5 and h in (50,60); print('OK: 5 seconds on BIOS clock')"
	CLOCK_OUT="$(CURDIR)/build/demo/clock-tenths.txt" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_clock_tenths.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,c=map(int,Path('build/demo/clock-tenths.txt').read_text().split()); assert 3<=a-b<=5 and 11<=a-c<=13; print('OK: displayed tenths follow the clock')"

.PHONY: test-cpu-visual
test-cpu-visual: demo
	$(PYTHON) tools/check_cpu_skin.py
	mkdir -p build/demo/frame-capture
	FRAMES_OUT="$(CURDIR)/build/demo/frame-capture" timeout 20s "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_visible_frames.tcl
	$(PYTHON) tools/check_visible_frames.py

.PHONY: test-jump-support test-speed
test-jump-support: demo
	for scenario in test_vault_auto test_clear_jump test_tall_wall; do SUPPORT_TRACE="$(CURDIR)/build/demo/$$scenario-check" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script "tools/$$scenario.tcl" -script tools/test_support_trace.tcl || exit 1; done
	$(PYTHON) -c "from pathlib import Path; read=lambda n:[list(map(float,l.split())) for l in Path('build/demo/'+n+'-check').read_text().splitlines()]; support=read('test_vault_auto'); clear=read('test_clear_jump'); assert {64,96} <= {int(r[7]) for r in support if r[6] and r[8]==664} and any(r[5]>0 for r in clear) and not any(r[6]>0 for r in clear); assert max(r[1]+256*r[2] for r in support)>=242 and max(r[1]+256*r[2] for r in clear)>=242; print('OK: landing uses hand support; clear jump does not')"
	$(PYTHON) tools/check_tall_support.py

test-speed: demo
	SPEED_OUT="$(CURDIR)/build/demo/speed.txt" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_speed.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,t,u=map(int,Path('build/demo/speed.txt').read_text().split()); assert 170<=b-a<=190 and t-u==2; print('OK: CPU advances about 90 pixels/s and timer tracks seconds')"

.PHONY: test-step3-directions
test-step3-directions: build-step3-visual
	STEP3_DIRECTION_OUT="$(CURDIR)/build/step3/direction-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_directions.tcl
	$(PYTHON) -c "from pathlib import Path; x,p,d,start,back,q,bd,boost,jump,jump_power,left,ld=map(int,Path('build/step3/direction-test/result.txt').read_text().split()); assert x>40 and p>=3 and d==3 and start==440 and back<start and q>=3 and bd==5 and boost>q and jump>0 and jump_power<=q and left<x and ld==7, (x,p,d,start,back,q,bd,boost,jump,jump_power,left,ld); print('OK: steering, reverse, minimum power, SPACE boost and M jump')"

.PHONY: test-step3-direction-speed
test-step3-direction-speed: build-step3-visual
	STEP3_SPEED_RESULT="$(CURDIR)/build/step3/direction-speed.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_direction_speed.tcl
	$(PYTHON) -c "from pathlib import Path; sl,sh,bl,bh,f=map(int,Path('build/step3/direction-speed.txt').read_text().split()); assert 0<sl<sh and sh*2<=sl*3 and 0<bl<bh and abs(f-bh)<=4, (sl,sh,bl,bh,f); print('OK: modest lateral acceleration and equal forward/reverse speed',sl,sh,bl,bh,f)"

.PHONY: test-step3-shores
test-step3-shores: build-step3-visual
	STEP3_SHORES_OUT="$(CURDIR)/build/step3/shore-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_shores.tcl
	$(PYTHON) tools/check_step3_shores.py

.PHONY: test-step3-cpu-course
test-step3-cpu-course: build-step3-visual
	STEP3_CPU_COURSE_RESULT="$(CURDIR)/build/step3/cpu-course.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_cpu_course.tcl
	$(PYTHON) -c "from pathlib import Path; at20,at30,_=map(int,Path('build/step3/cpu-course.txt').read_text().split()); assert at20>=2048 and at30>=3328, (at20,at30); print('OK: CPU crosses land, reaches river and finishes',at20,at30)"

.PHONY: test-step3-boat-knock
test-step3-boat-knock: build-step3-visual
	STEP3_BOAT_KNOCK_RESULT="$(CURDIR)/build/step3/boat-knock.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_boat_knock.tcl
	$(PYTHON) -c "from pathlib import Path; boat,fall,status=map(int,Path('build/step3/boat-knock.txt').read_text().split()); assert boat==0 and fall>0 and status in (0,2), (boat,fall,status); print('OK: a swimmer throws the boater into the river and can take the boat')"

.PHONY: test-step3-water-obstacles
test-step3-water-obstacles: build-step3-visual
	STEP3_WATER_OBSTACLES_RESULT="$(CURDIR)/build/step3/water-obstacles.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_water_obstacles.tcl
	$(PYTHON) -c "from pathlib import Path; rock,avoid,log,boat=map(int,Path('build/step3/water-obstacles.txt').read_text().split()); assert rock>0 and avoid==0 and log>0 and boat==0, (rock,avoid,log,boat); print('OK: swimmer hits rock and log; can avoid rock')"

.PHONY: test-step3-bridges
test-step3-bridges: build-step3-visual
	STEP3_BRIDGE_OUT="$(CURDIR)/build/step3/bridge-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_bridges.tcl
	STEP3_BRIDGE_CPU_RESULT="$(CURDIR)/build/step3/bridge-cpu.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step3/visual.rom" -romtype ASCII16 -script tools/test_step3_bridge_cpu.tcl
	$(PYTHON) tools/check_step3_bridges.py

.PHONY: test-step3-integration
test-step3-integration: demo
	for hits in 52 68; do SHOOT_HITS=$$hits STEP3_INTEGRATION_OUT="$(CURDIR)/build/demo/step3-integration-$$hits" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step3_integration.tcl || exit 1; $(PYTHON) tools/check_step3_integration.py "build/demo/step3-integration-$$hits" $$hits || exit 1; done

.PHONY: test-step3-to-step4
test-step3-to-step4: demo
	for remaining in 1 8 10; do full=0; if [ $$remaining = 8 ]; then full=1; fi; STEP3_REMAINING=$$remaining STEP4_FULL_TEST=$$full STEP3_TO_STEP4_OUT="$(CURDIR)/build/demo/step3-to-step4-$$remaining" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step3_to_step4.tcl || exit 1; $(PYTHON) tools/check_step3_to_step4.py "build/demo/step3-to-step4-$$remaining" $$remaining || exit 1; done
	STEP3_FAIL_RESULT="$(CURDIR)/build/demo/step3-fail-transition.txt" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_step3_fail_transition.tcl
	$(PYTHON) -c "from pathlib import Path; a=list(map(int,Path('build/demo/step3-fail-transition.txt').read_text().split())); assert a==[7,1,3,0], a; print('OK: Step 3 timeout does not advance')"

.PHONY: build-step4-visual run-step4-visual
build-step4-visual:
	$(PYTHON) tools/build_step4_visual.py
	cd src && sjasm step4_visual.asm ../build/step4/visual.rom

run-step4-visual: build-step4-visual
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl

.PHONY: test-step4-visual
test-step4-visual: build-step4-visual
	STEP4_TEST_OUT="$(CURDIR)/build/step4/test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_visual.tcl
	$(PYTHON) -c "from pathlib import Path; from PIL import Image; a,b,h,t,sec=map(int,Path('build/step4/test/result.txt').read_text().split()); im=Image.open('build/step4/test/playing.png').convert('RGB'); assert b>a and h==1 and t==0 and 0<sec<=40 and len(im.getcolors(im.width*im.height))>8, (a,b,h,t,sec); print('OK: lateral movement, shot, target hit and visible screen')"
	for hits in 51 52; do STEP4_HITS=$$hits STEP4_RESULT="$(CURDIR)/build/step4/result-$$hits.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/test_step4_result.tcl || exit 1; done
	$(PYTHON) -c "from pathlib import Path; read=lambda n:list(map(int,Path('build/step4/result-'+str(n)+'.txt').read_text().split())); a,b=read(51),read(52); assert a==[2,0,51] and b==[1,0,52], (a,b); print('OK: timeout fails below 52 and qualifies at 52')"
	STEP4_GOAL_OUT="$(CURDIR)/build/step4/goal" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_goal.tcl
	$(PYTHON) tools/check_step4_goal.py
	STEP4_GRID_OUT="$(CURDIR)/build/step4/grid" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_grid.tcl
	$(PYTHON) tools/check_step4_grid.py

.PHONY: test-step4-waves
test-step4-waves: build-step4-visual
	STEP4_CLEAR=0 STEP4_TIMELINE_RESULT="$(CURDIR)/build/step4/timeline.txt" STEP4_TIMELINE_SCREEN="$(CURDIR)/build/step4/timeline.png" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_timeline.tcl
	$(PYTHON) tools/check_step4_recording.py
	STEP4_HITBOX_RESULT="$(CURDIR)/build/step4/hitbox.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/test_step4_hitbox.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,c,k=map(int,Path('build/step4/hitbox.txt').read_text().split()); assert (a,b,c,k)==(0,1,0,1), (a,b,c,k); print('OK: shot misses outside and hits within small target')"
	STEP4_SIZE_RESULT="$(CURDIR)/build/step4/target-sizes.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/test_step4_target_sizes.tcl
	$(PYTHON) -c "from pathlib import Path; a=list(map(int,Path('build/step4/target-sizes.txt').read_text().split())); assert a==[12,12,26], a; print('OK: target size changes with depth',a)"
	STEP4_CLIPPING_RESULT="$(CURDIR)/build/step4/clipping.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/test_step4_clipping.tcl
	$(PYTHON) -c "from pathlib import Path; a=list(map(int,Path('build/step4/clipping.txt').read_text().split())); assert a==[14,6], a; print('OK: normal and clipped target widths',a)"
	STEP4_RETURN_RESULT="$(CURDIR)/build/step4/return.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/test_step4_return.tcl
	$(PYTHON) -c "from pathlib import Path; a=list(map(int,Path('build/step4/return.txt').read_text().split())); assert a==[0,1,3,1], a; print('OK: a hit stays removed through the return',a)"
	STEP4_FRAGMENTS_RESULT="$(CURDIR)/build/step4/fragments.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/test_step4_fragments.tcl
	$(PYTHON) -c "from pathlib import Path; a=list(map(int,Path('build/step4/fragments.txt').read_text().split())); assert a==[0,1,1], a; print('OK: destroyed robot stays removed while the others go on',a)"
	for survivor in none 31; do STEP4_SURVIVOR=$$survivor STEP4_CONVOY_RESULT="$(CURDIR)/build/step4/convoy-$$survivor.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/test_step4_convoy.tcl || exit 1; done
	$(PYTHON) -c "from pathlib import Path; f=lambda n:list(map(int,Path('build/step4/convoy-'+n+'.txt').read_text().split())); a,b=f('none'),f('31'); assert a==[0,0,0,0,0,0] and b==[1,1,0,1,1,0], (a,b); print('OK: loop keeps individual convoy hits',a,b)"
	STEP4_EFFECTS_OUT="$(CURDIR)/build/step4/effects" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_effects.tcl
	$(PYTHON) tools/check_step4_effects.py
	STEP4_MULTISHOT_OUT="$(CURDIR)/build/step4/multishot" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_multishot.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,c,d,e=map(int,Path('build/step4/multishot/result.txt').read_text().split()); assert a>=3 and b>=3 and (c,d,e)==(1,1,0), (a,b,c,d,e); print('OK: simultaneous shots and collision from an extra slot')"
	STEP4_WALK_OUT="$(CURDIR)/build/step4/walk" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_walk.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,c,d,e=map(int,Path('build/step4/walk/result.txt').read_text().split()); assert b>a and c<b and (d,e)==(1,2), (a,b,c,d,e); print('OK: independent right and left running poses')"
	STEP4_TAIL_RESULT="$(CURDIR)/build/step4/tail.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/test_step4_tail.tcl
	$(PYTHON) -c "from pathlib import Path; a=list(map(int,Path('build/step4/tail.txt').read_text().split())); assert a[:3]==[0,0,1] and a[3]>0 and a[4]>0, a; print('OK: robots keep moving near timeout',a)"
	STEP4_FINAL_LOOP_RESULT="$(CURDIR)/build/step4/final-loop.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/test_step4_final_loop.tcl
	$(PYTHON) -c "from pathlib import Path; a=list(map(int,Path('build/step4/final-loop.txt').read_text().split())); assert a==[38,0,0,8,0,0,7,1], a; print('OK: 0:39.0 (38.9 at the first tick) and last survivors keep moving',a)"

.PHONY: test-step4-views
test-step4-views: build-step4-visual
	STEP4_VIEWS_OUT="$(CURDIR)/build/step4/views" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_views.tcl
	$(PYTHON) -c "from pathlib import Path; fx,fy,rx,ry,lx,ly,bx,by=map(int,Path('build/step4/views/result.txt').read_text().split()); assert (fx,fy,rx,ry,lx,ly,bx,by)==(19,64,96,64,26,96,19,64), (fx,fy,rx,ry,lx,ly,bx,by); print('OK: front, side and rear views')"
	$(PYTHON) tools/check_step4_direction.py
	STEP4_BLINK_OUT="$(CURDIR)/build/step4/blink" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_blink.tcl
	$(PYTHON) tools/check_step4_blink.py

.PHONY: test-step4-integration
test-step4-integration: demo
	for hits in 52 53 54 55 56 57 58 59 60 63 64 65; do STEP3_REMAINING=8 STEP4_HITS=$$hits STEP3_TO_STEP4_OUT="$(CURDIR)/build/demo/step4-integration-$$hits" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_integration.tcl || exit 1; $(PYTHON) tools/check_step4_integration.py "build/demo/step4-integration-$$hits" $$hits || exit 1; done

.PHONY: test-result-graphics
test-result-graphics: demo
	$(PYTHON) tools/check_result_graphics.py

.PHONY: build-step5-visual run-step5-visual
build-step5-visual:
	$(PYTHON) tools/build_step5_assets.py
	cd src && sjasm step5_visual.asm ../build/step5/visual.rom

run-step5-visual: build-step5-visual
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step5/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl

.PHONY: test-step5-integration
test-step5-integration: demo
	for win in 0 1; do STEP3_REMAINING=8 STEP4_HITS=58 STEP5_WIN=$$win STEP3_TO_STEP4_OUT="$(CURDIR)/build/demo/step5-$$win" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step5_integration.tcl || exit 1; $(PYTHON) tools/check_step5_integration.py "build/demo/step5-$$win" $$win || exit 1; done

.PHONY: run-step6-visual test-step6
run-step6-visual: demo
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/run_step6_visual.tcl

test-step6: demo
	for elapsed in 0 1; do STEP6_WAVE_ELAPSED=$$elapsed STEP6_OUT="$(CURDIR)/build/demo/step6-penalty-$$elapsed" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step6_penalty.tcl || exit 1; $(PYTHON) tools/check_step6_penalty.py "build/demo/step6-penalty-$$elapsed" $$elapsed || exit 1; done
	for hits in 31 32 33 34 35 36 37 40; do STEP6_HITS=$$hits STEP6_OUT="$(CURDIR)/build/demo/step6-result-$$hits" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step6_result.tcl || exit 1; $(PYTHON) tools/check_step6_result.py "build/demo/step6-result-$$hits" $$hits || exit 1; done
	for win in 0 1; do STEP3_REMAINING=8 STEP4_HITS=58 STEP5_WIN=$$win STEP3_TO_STEP4_OUT="$(CURDIR)/build/demo/step6-path-$$win" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step6_path.tcl || exit 1; STEP6_WIN=$$win $(PYTHON) -c "import os; from pathlib import Path; w=int(os.environ['STEP6_WIN']); a=list(map(int,Path('build/demo/step6-path-'+str(w)+'/step6-start.txt').read_text().split())); assert a[:4]==[17,1,24+3*w,31] and a[4] not in (0,31), a; print('OK: Step 5 enters Step 6 with correct carried time',a)" || exit 1; done

.PHONY: extract-penalty-arcade build-penalty-visual run-penalty-visual test-penalty-visual
# Needs the MAME captures listed in tools/extract_penalty.py.
extract-penalty-arcade:
	$(PYTHON) tools/extract_penalty.py

build-penalty-visual:
	$(PYTHON) tools/build_penalty.py
	cd src && sjasm penalty.asm ../build/penalty/visual.rom
	sed -e 's/^PEN_BASE equ 0 /PEN_BASE equ 123/' -e "s/^RANK_BANK equ 0 /RANK_BANK equ $$(cat build/mission/ending-bank.txt) /" -e 's#"../build/penalty/#"#' -e 's#"../build/demo/#"../demo/#' -e 's#"psg_calls.asm"#"../../src/psg_calls.asm"#' src/penalty.asm > build/penalty/integrated.asm
	grep -q '^PEN_BASE equ 123' build/penalty/integrated.asm
	grep -q '^RANK_BANK equ [1-9]' build/penalty/integrated.asm
	cd build/penalty && sjasm integrated.asm integrated.rom
	$(PYTHON) -c "from pathlib import Path; p=Path('build/penalty/visual.rom'); d=p.read_bytes(); assert len(d)<=0xc000; p.write_bytes(d+bytes([0xff])*(0x10000-len(d)))"

run-penalty-visual: build-penalty-visual
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/penalty/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl

test-penalty-visual: build-penalty-visual
	for mode in win lose; do PENALTY_MODE=$$mode PENALTY_OUT="$(CURDIR)/build/penalty/visual-$$mode" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/penalty/visual.rom" -romtype ASCII16 -script tools/test_penalty_visual.tcl || exit 1; done

.PHONY: test-penalty-integrated
test-penalty-integrated: demo
	for case in step1win step1then2 step1lose step2 step2far step2used step4over step7over; do PEN_CASE=$$case PEN_OUT="$(CURDIR)/build/demo/penalty-$$case" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_penalty_integrated.tcl || exit 1; cat "build/demo/penalty-$$case/result.txt"; done
	$(PYTHON) -c "from pathlib import Path; r={c:Path('build/demo/penalty-'+c+'/result.txt').read_text().split() for c in ('step1win','step1then2','step1lose','step2','step2far','step2used','step4over','step7over')}; assert r['step1win']==['step1win','1','7','step2','time=35','used=1'],r; assert r['step1lose']==['step1lose','1','7','title','used=0'],r; assert r['step2'][:4]==['step2','2','8','step3'] and r['step2'][5]=='used=1',r; assert r['step1then2'][1:]==['1','7','title','over=1','used=0'],r; assert all(r[c][3:]==['title','over=1','used=0'] for c in ('step2far','step2used','step4over','step7over')),r; print('OK: penalty once per game, 7/8 chin-ups, next step without bonus, GAME OVER to the title, also when a step is lost without penalty')"

.PHONY: test-ranking-integrated
test-ranking-integrated: demo
	RANK_OUT="$(CURDIR)/build/demo/ranking-test" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/test_ranking_integrated.tcl
	$(PYTHON) tools/check_ranking_integrated.py

.PHONY: build-step7-visual run-step7-visual
capture-step7-arcade:
	mkdir -p build/step7/mame
	COMBAT_DUMP="$(CURDIR)/build/step7/mame" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/step7/mame" -autoboot_script tools/mame_step7_capture.lua
	$(PYTHON) tools/render_background.py build/step7/mame/frame-1050 --out build/step7/background
	$(PYTHON) tools/extract_step7_sprites.py

build-step7-visual:
	$(PYTHON) tools/build_step7_visual.py
	$(PYTHON) tools/build_step7_ending.py
	cd src && sjasm step7_visual.asm ../build/step7/visual.rom

run-step7-visual: build-step7-visual
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl

.PHONY: test-step7-visual
test-step7-visual: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_visual.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,k,j,video=Path('build/step7/visual-test/result.txt').read_text().split(); assert int(b)>int(a) and int(k)>0 and int(j)>0 and video=='GFX9000', (a,b,k,j,video); print('OK: movement, kick, jump and V9990 output')"

.PHONY: test-step7-diagonal
test-step7-diagonal: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_diagonal.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,j,c,d,k,e,f,l=map(int,Path('build/step7/visual-test/diagonal.txt').read_text().split()); assert b>a and d<c and e==f and min(j,k,l)>0, (a,b,j,c,d,k,e,f,l); print('OK: diagonal jumps retain direction; vertical jump stays in place')"

.PHONY: test-step7-facing-jump
test-step7-facing-jump: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_facing_jump.tcl
	$(PYTHON) -c "from pathlib import Path; l,held,r,h,t,back=map(int,Path('build/step7/visual-test/facing-jump.txt').read_text().split()); assert (l,held,r,back)==(0,0,0,1) and 39<=h<=42 and t>0, (l,held,r,h,t,back); print('OK: stepping back keeps facing the instructor, jump reaches expected height')"

.PHONY: test-step7-combat
test-step7-combat: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_combat.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,w,h,l,p=map(int,Path('build/step7/visual-test/combat.txt').read_text().split()); assert b<a and (w,h,l,p)==(1,0,2,0), (a,b,w,h,l,p); print('OK: instructor approaches and both fighters can win')"

.PHONY: test-step7-damage
test-step7-damage: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_damage.tcl
	$(PYTHON) tools/check_step7_damage.py

.PHONY: test-step7-walk
test-step7-walk: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_walk.tcl
	$(PYTHON) tools/check_step7_walk.py

.PHONY: capture-step7-walk
capture-step7-walk:
	mkdir -p build/step7/walk-mame
	COMBAT_DUMP="$(CURDIR)/build/step7/walk-mame" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/step7/walk-mame" -autoboot_script tools/mame_step7_walk_capture.lua
	STEP7_CAPTURE=walk $(PYTHON) tools/extract_step7_sprites.py

.PHONY: test-step7-repeat
test-step7-repeat: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_repeat.tcl
	$(PYTHON) -c "from pathlib import Path; n,x,c,p,r=map(int,Path('build/step7/visual-test/repeat.txt').read_text().split()); assert n>=3 and x>100 and 0<c<8 and p==8 and r==0,(n,x,c,p,r); print('OK: repeated kicks connect and instructor recoils')"

.PHONY: test-step7-hit-range
test-step7-hit-range: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_hit_range.tcl
	$(PYTHON) -c "from pathlib import Path; a=tuple(map(int,Path('build/step7/visual-test/hit-range.txt').read_text().split())); assert a==(8,7,8,7,8,8),a; print('OK: hits require visible range and correct facing in both directions')"

.PHONY: test-step7-impact
test-step7-impact: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_impact.tcl
	$(PYTHON) tools/check_step7_impact.py

.PHONY: test-step7-pressure
test-step7-pressure: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_pressure.tcl
	$(PYTHON) -c "from pathlib import Path; p,x,h,r,php,attack=map(int,Path('build/step7/visual-test/pressure.txt').read_text().split()); assert p==70 and x-p>=41 and 0<h<8 and r==0 and php<8,(p,x,h,r,php,attack); print('OK: stationary repeated kicks cannot defeat instructor; natural counterattack connects')"

.PHONY: test-step7-corner
test-step7-corner: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_corner.tcl
	$(PYTHON) -c "from pathlib import Path; rp,rc,lp,lc=map(int,Path('build/step7/visual-test/corner.txt').read_text().split()); assert rp<8 and lp<8 and rc>0 and lc>0,(rp,rc,lp,lc); print('OK: cornered instructor can counter from both sides')"

.PHONY: capture-step7-ko
capture-step7-ko:
	for loser in instructor player; do if [ "$$loser" = instructor ]; then kind=ko; else kind=player-ko; fi; mkdir -p "$(CURDIR)/build/step7/$$kind-mame"; STEP7_LOSER=$$loser COMBAT_DUMP="$(CURDIR)/build/step7/$$kind-mame" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/step7/$$kind-mame" -autoboot_script tools/mame_step7_ko_capture.lua || exit 1; STEP7_CAPTURE=$$kind $(PYTHON) tools/extract_step7_sprites.py || exit 1; done

.PHONY: test-step7-ending
test-step7-ending: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/ceremony-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_ceremony.tcl
	$(PYTHON) tools/check_step7_ceremony.py

.PHONY: test-step7-integrated
test-step7-integrated: demo
	STEP7_INTEGRATED_OUT="$(CURDIR)/build/demo/step7-integrated-test" "$(OPENMSX)" -script tools/test_skip_intro.tcl -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_integrated.tcl
	$(PYTHON) -c "from pathlib import Path; a=list(map(int,Path('build/demo/step7-integrated-test/path.txt').read_text().split())); assert a==[1,1,1,1,1,1,1,1,268001],a; print('OK: Step 6 bonus, map, combat and victory sequence retain the accumulated score')"
	$(PYTHON) -c "from pathlib import Path; p=Path('build/step7'); r=Path('build/demo/step7-integrated-test/combat-vram.bin').read_bytes(); v=bytearray(len(r)); v[::2]=r[:0x40000]; v[1::2]=r[0x40000:]; f=bytearray((p/'field.bin').read_bytes()[:27136]); g=v[65536:65536+27136]; [g.__setitem__(slice(y*128+52,y*128+76),bytes(24)) or f.__setitem__(slice(y*128+52,y*128+76),bytes(24)) for y in range(26,39)]; [g.__setitem__(slice(y*128+2,y*128+40),bytes(38)) or f.__setitem__(slice(y*128+2,y*128+40),bytes(38)) for y in range(1,14)]; assert g==f; assert v[98304:98304+57344]==(p/'atlas.bin').read_bytes()[:57344]; assert v[163840:163840+40960]==(p/'atlas2.bin').read_bytes(); print('OK: packed combat graphics (clock and score areas aside) and the bank-73 atlas load intact')"
	$(PYTHON) tools/check_step7_rank.py 268001 build/demo/step7-integrated-test

.PHONY: test-step7-ranks
test-step7-ranks: build-step7-visual
	for score in 0 200000 200001 220000 220001 240000 240001 260000 260001 999999 1000000; do STEP7_SCORE=$$score STEP7_RANK_OUT="$(CURDIR)/build/step7/rank-$$score" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_rank.tcl || exit 1; $(PYTHON) tools/check_step7_rank.py $$score "build/step7/rank-$$score" || exit 1; done

.PHONY: test-step7-lowkick
test-step7-lowkick: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_lowkick.tcl
	$(PYTHON) -c "from pathlib import Path; c,l,lh,h,s,hh=map(int,Path('build/step7/visual-test/lowkick.txt').read_text().split()); assert (c,l,h,s)==(1,1,0,0) and lh<8 and hh<lh, (c,l,lh,h,s,hh); print('OK: down crouches, down+kick sweeps and hits, kick alone is high')"

.PHONY: test-step7-rules
test-step7-rules: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_rules.tcl
	$(PYTHON) -c "from pathlib import Path; t=Path('build/step7/visual-test/rules.txt').read_text().split('|'); a=t[0].split(); s=set(t[1].split()); r=t[2].split(); assert a[0]=='1' and a[1]=='60.0' and a[2]=='8' and a[3:]==['0'] and s=={'0','1','2'} and r==['2','1'], t; print('OK: READY at 1:00.0, crouching dodges high kicks, three instructor attacks, TIME UP loses')"

.PHONY: test-step7-knockdown
test-step7-knockdown: build-step7-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/step7/visual-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step7/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step7_knockdown.tcl
	$(PYTHON) tools/check_step7_knockdown.py

.PHONY: capture-step7-ceremony
capture-step7-ceremony:
	mkdir -p build/step7/ceremony-mame
	SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/step7/ceremony-mame" -autoboot_script tools/mame_step7_ceremony_capture.lua
	$(PYTHON) tools/extract_step7_ceremony.py build/step7/ceremony-mame

.PHONY: capture-step7-ending
capture-step7-ending:
	mkdir -p build/step7/ending-mame
	SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/step7/ending-mame" -autoboot_script tools/mame_step7_ending_capture.lua

.PHONY: capture-mission-arcade
capture-mission-arcade:
	mkdir -p build/mission/mame
	COMBAT_DUMP="$(CURDIR)/build/mission/mame" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/mame" -autoboot_script tools/mame_mission_capture.lua
	mkdir -p build/mission/attack-mame
	MISSION_CAPTURE_ACTION=attack COMBAT_DUMP="$(CURDIR)/build/mission/attack-mame" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/attack-mame" -autoboot_script tools/mame_mission_capture.lua
	mkdir -p build/mission/airkick-mame
	MISSION_CAPTURE_ACTION=airkick COMBAT_DUMP="$(CURDIR)/build/mission/airkick-mame" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/airkick-mame" -autoboot_script tools/mame_mission_capture.lua
	mkdir -p build/mission/enemy-mame
	MISSION_CAPTURE_ACTION=enemy COMBAT_DUMP="$(CURDIR)/build/mission/enemy-mame" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/enemy-mame" -autoboot_script tools/mame_mission_capture.lua
	mkdir -p build/mission/enemyattack-mame
	MISSION_CAPTURE_ACTION=enemyattack COMBAT_DUMP="$(CURDIR)/build/mission/enemyattack-mame" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/enemyattack-mame" -autoboot_script tools/mame_mission_capture.lua
	$(PYTHON) tools/extract_mission_assets.py
	$(PYTHON) tools/check_mission_arcade_capture.py

.PHONY: build-mission-visual run-mission-visual test-mission-door-front test-mission-walk-timing test-mission-kick-reach test-mission-chain-entry test-mission-prelude test-mission-ending
build-mission-visual:
	$(PYTHON) tools/build_mission_music.py
	$(PYTHON) tools/build_mission_visual.py
	cd src && sjasm ../build/mission/visual.asm ../build/mission/visual.rom

.PHONY: capture-mission-orange
capture-mission-orange:
	mkdir -p build/mission/orangehit-mame
	MISSION_CAPTURE_ACTION=orangehit COMBAT_DUMP="$(CURDIR)/build/mission/orangehit-mame" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/orangehit-mame" -autoboot_script tools/mame_mission_capture.lua
	$(PYTHON) tools/extract_mission_assets.py

run-mission-visual: build-mission-visual
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl

.PHONY: test-mission-visual
test-mission-visual: build-mission-visual
	STEP7_VISUAL_OUT="$(CURDIR)/build/mission/test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_visual.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,k,j,video=Path('build/mission/test/result.txt').read_text().split(); assert int(b)>int(a) and int(k)>0 and int(j)>0 and video=='GFX9000',(a,b,k,j,video); print('OK: first-room movement, attack, jump and V9990 display')"

.PHONY: test-mission-facing
test-mission-facing: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/facing-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_facing.tcl
	$(PYTHON) tools/check_mission_facing.py

.PHONY: test-mission-scroll
test-mission-scroll: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/scroll-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_scroll.tcl
	$(PYTHON) tools/check_mission_scroll.py

.PHONY: test-mission-airkick
test-mission-airkick: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/airkick-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_airkick.tcl
	$(PYTHON) tools/check_mission_airkick.py

.PHONY: test-mission-enemy
test-mission-enemy: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/enemy-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_enemy.tcl
	$(PYTHON) tools/check_mission_enemy.py

.PHONY: test-mission-damage-cells
test-mission-damage-cells: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/damage-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_damage_cells.tcl
	$(PYTHON) tools/check_mission_damage_cells.py

.PHONY: test-mission-two-enemies
test-mission-two-enemies: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/two-enemies-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_two_enemies.tcl
	$(PYTHON) tools/check_mission_two_enemies.py

.PHONY: test-mission-spawn
test-mission-spawn: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/spawn-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_spawn.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,c,d,s,t,hp=map(int,Path('build/mission/spawn-test/spawn.txt').read_text().split()); assert b>a and d<c and s==t==1 and hp==8,(a,b,c,d,s,t,hp); print('OK: both assailants appear naturally and approach from opposite sides')"

.PHONY: test-mission-performance
test-mission-performance: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/performance-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_performance.tcl
	$(PYTHON) -c "from pathlib import Path; a,b,c,d,e=[int(x.split()[1]) for x in Path('build/mission/performance-test/performance.txt').read_text().splitlines()]; assert b<=80 and c<=80 and d<=80 and e<=90,(a,b,c,d,e); print(f'OK: jump takes {a}, {b}, {c}, {d}, {e} frames with increasing scene load')"

.PHONY: test-mission-impact
test-mission-impact: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/impact-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_impact.tcl
	$(PYTHON) tools/check_mission_impact.py

.PHONY: test-mission-grab
test-mission-grab: build-mission-visual
	for facing in 0 1; do export MISSION_GRAB_FACING=$$facing MISSION_TEST_OUT="$(CURDIR)/build/mission/grab-test-$$facing"; "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_grab.tcl && $(PYTHON) tools/check_mission_grab.py || exit 1; done

.PHONY: test-mission-thrower
test-mission-thrower: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/thrower-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_thrower.tcl
	$(PYTHON) tools/check_mission_thrower.py

.PHONY: test-mission-walk
test-mission-walk: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/walk-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_walk.tcl
	$(PYTHON) tools/check_mission_walk.py

.PHONY: test-mission-orange-fall
test-mission-orange-fall: build-mission-visual
	for facing in 0 1; do export MISSION_ORANGE_FACING=$$facing MISSION_TEST_OUT="$(CURDIR)/build/mission/orange-fall-test-$$facing"; "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_orange_fall.tcl && $(PYTHON) tools/check_mission_orange_fall.py || exit 1; done

.PHONY: test-mission-waves
test-mission-waves: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/waves-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_waves.tcl
	$(PYTHON) tools/check_mission_waves.py

.PHONY: test-mission-doorway test-mission-ground
test-mission-doorway: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/doorway-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_doorway.tcl
	$(PYTHON) tools/check_mission_doorway.py
test-mission-door-front: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/door-front-test" MISSION_LOOP=0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+loop:)' build/mission/visual.lst | head -1) "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_door_front.tcl
	$(PYTHON) tools/check_mission_door_front.py
MISSION_LOOP_ADDR=0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+loop:)' build/mission/visual.lst | head -1)
MISSION_IDLE_ADDR=0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+\.wait_start:)' build/mission/visual.lst | head -1)
test-mission-walk-timing: build-mission-visual
	MISSION_LOOPS=1500 MISSION_TEST_OUT="$(CURDIR)/build/mission/walk-timing-test" MISSION_LOOP=$(MISSION_LOOP_ADDR) MISSION_IDLE=$(MISSION_IDLE_ADDR) "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_walk_timing.tcl
	$(PYTHON) tools/check_mission_walk_timing.py
test-mission-kick-reach: build-mission-visual
	for d in 20 32 34 40; do MISSION_KICK_DIST=$$d MISSION_TEST_OUT="$(CURDIR)/build/mission/kick-reach-$$d" MISSION_LOOP=$(MISSION_LOOP_ADDR) "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_kick_reach.tcl || exit 1; cat build/mission/kick-reach-$$d/result.txt; done
	$(PYTHON) tools/check_mission_kick_reach.py
test-mission-chain-entry: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/chain-entry-test" MISSION_LOOP=$(MISSION_LOOP_ADDR) "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_chain_entry.tcl
	$(PYTHON) tools/check_mission_chain_entry.py
test-mission-prelude: build-mission-visual
	PRELUDE_ATTENTION=$$(printf %d 0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+prelude_attention:)' build/mission/visual.lst)) PRELUDE_MANSION=$$(printf %d 0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+prelude_mansion:)' build/mission/visual.lst)) MISSION_TEST_OUT="$(CURDIR)/build/mission/prelude-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_mission_prelude.tcl
	$(PYTHON) tools/check_mission_prelude.py
test-mission-ending: build-mission-visual
	PRELUDE_ENDING=$$(printf %d 0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+prelude_ending:)' build/mission/visual.lst)) MISSION_TEST_OUT="$(CURDIR)/build/mission/ending-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_ending.tcl
	$(PYTHON) tools/check_mission_ending.py
.PHONY: capture-mission-ending
capture-intro-full:
	mkdir -p build/mame-intro-full
	INTRO_FIRST=370 INTRO_LAST=810 SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mame-intro-full" -autoboot_script tools/mame_intro_full_capture.lua
	$(PYTHON) tools/extract_mission_prelude.py
.PHONY: capture-intro-full
capture-mission-ending:
	mkdir -p build/mission/ending-mame build/mission/ending-mame-early
	SDL_VIDEODRIVER=dummy MISSION_BOSS_HITS=1 CAP_FROM=8000 CAP_TO=9400 $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/ending-mame-early" -autoboot_script tools/mame_mission_ending_capture.lua
	SDL_VIDEODRIVER=dummy MISSION_BOSS_HITS=1 $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/ending-mame" -autoboot_script tools/mame_mission_ending_capture.lua
	$(PYTHON) tools/extract_mission_ending.py build/mission/ending-mame
	$(PYTHON) tools/extract_mission_prelude.py
.PHONY: capture-mission-prelude
capture-mission-prelude:
	mkdir -p build/mission/prelude-mame
	SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/prelude-mame" -autoboot_script tools/mame_mission_prelude_capture.lua
	$(PYTHON) tools/extract_mission_prelude.py build/mission/prelude-mame
test-mission-ground: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/ground-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_ground.tcl
	$(PYTHON) tools/check_mission_ground.py

.PHONY: test-mission-crates
test-mission-crates: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/crates-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_crates.tcl
	$(PYTHON) tools/check_mission_crates.py

.PHONY: test-mission-crates-enemy
test-mission-crates-enemy: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/crates-enemy-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_crates_enemy.tcl
	$(PYTHON) tools/check_mission_crates_enemy.py

.PHONY: test-mission-second-crate
test-mission-second-crate: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/second-crate-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_second_crate.tcl
	$(PYTHON) tools/check_mission_second_crate.py

.PHONY: test-mission-fire
test-mission-fire: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/fire-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_fire.tcl
	$(PYTHON) tools/check_mission_fire.py

.PHONY: test-mission-knife-kick
test-mission-knife-kick: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/knife-kick-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_knife_kick.tcl
	$(PYTHON) tools/check_mission_knife_kick.py

.PHONY: test-mission-molotov-spawn
test-mission-molotov-spawn: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/molotov-spawn-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_molotov_spawn.tcl
	$(PYTHON) tools/check_mission_molotov_spawn.py

.PHONY: test-mission-molotov-arc
test-mission-molotov-arc: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/molotov-arc-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_molotov_arc.tcl
	$(PYTHON) tools/check_mission_molotov_arc.py

.PHONY: test-mission-molotov-gap
test-mission-molotov-gap: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/molotov-gap-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_molotov_gap.tcl
	$(PYTHON) tools/check_mission_molotov_gap.py

.PHONY: test-mission-page-stability
test-mission-page-stability: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/page-stability-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_page_stability.tcl
	$(PYTHON) tools/check_mission_page_stability.py
	MISSION_PAGE_CLOSE=1 MISSION_TEST_OUT="$(CURDIR)/build/mission/page-stability-close-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_page_stability.tcl
	MISSION_TEST_OUT="$(CURDIR)/build/mission/page-stability-close-test" $(PYTHON) tools/check_mission_page_stability.py
	MISSION_PAGE_FIRE=1 MISSION_TEST_OUT="$(CURDIR)/build/mission/page-stability-fire-test" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_page_stability.tcl
	MISSION_TEST_OUT="$(CURDIR)/build/mission/page-stability-fire-test" $(PYTHON) tools/check_mission_page_stability.py

.PHONY: capture-mission-course
capture-mission-course:
	mkdir -p build/mission/course-mame
	rm -rf build/mission/course-mame/frame-* build/mission/course-mame/combatsc
	MISSION_CAPTURE_ACTION=course COMBAT_DUMP="$(CURDIR)/build/mission/course-mame" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/course-mame" -autoboot_script tools/mame_mission_capture.lua
	$(PYTHON) tools/reconstruct_mission_course.py

.PHONY: capture-mission-doorway
capture-mission-doorway:
	mkdir -p build/mission/course-doorway-probe
	MISSION_CAPTURE_ACTION=course MISSION_COURSE_JUMP_PERIOD=50 MISSION_COURSE_END=9000 COMBAT_DUMP="$(CURDIR)/build/mission/course-doorway-probe" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/course-doorway-probe" -autoboot_script tools/mame_mission_capture.lua
	MISSION_COURSE_CAPTURE=course-doorway-probe MISSION_COURSE_OUTPUT=build/mission/course-doorway-reference.png $(PYTHON) tools/reconstruct_mission_course.py
	$(PYTHON) -c "from PIL import Image; im=Image.open('build/mission/course-doorway-reference.png'); assert im.size==(1048,212),im.size; im.crop((24,0,1048,212)).save('assets/mission/course-to-crates.png')"

.PHONY: capture-mission-expanded
capture-mission-expanded:
	rm -rf build/mission/course-beyond-probe
	mkdir -p build/mission/course-beyond-probe
	MISSION_CAPTURE_ACTION=course MISSION_COURSE_BYPASS=1 MISSION_COURSE_JUMP_PERIOD=50 MISSION_COURSE_END=11000 COMBAT_DUMP="$(CURDIR)/build/mission/course-beyond-probe" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/course-beyond-probe" -autoboot_script tools/mame_mission_capture.lua
	MISSION_COURSE_CAPTURE=course-beyond-probe MISSION_COURSE_OUTPUT=build/mission/course-beyond-reference.png $(PYTHON) tools/reconstruct_mission_course.py
	$(PYTHON) -c "from PIL import Image; im=Image.open('build/mission/course-beyond-reference.png'); assert im.width>=1792 and im.height==212,im.size; expanded=im.crop((im.width-1792,0,im.width,212)); old=Image.open('assets/mission/course-to-crates.png'); expanded.paste(old,(expanded.width-old.width,0)); expanded.save('assets/mission/course-expanded.png')"

.PHONY: test-mission-hang
test-mission-hang: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/hang-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_hang.tcl
	$(PYTHON) tools/check_mission_hang.py

.PHONY: test-mission-late-zone
test-mission-late-zone: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/late-zone-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_late_zone.tcl
	$(PYTHON) tools/check_mission_late_zone.py

.PHONY: test-mission-blue-knife
test-mission-blue-knife: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/blue-knife-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_blue_knife.tcl
	$(PYTHON) -c "from pathlib import Path; assert Path('build/mission/blue-knife-test/result.txt').read_text().strip() == '1 1 8'; print('OK: blue attacker launches a knife')"

.PHONY: test-mission-fire-barrier
test-mission-fire-barrier: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/fire-barrier-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_fire_barrier.tcl
	$(PYTHON) tools/check_mission_fire_barrier.py

.PHONY: test-mission-knife-pair
test-mission-knife-pair: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/knife-pair-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_knife_pair.tcl
	$(PYTHON) tools/check_mission_knife_pair.py

.PHONY: test-mission-later-encounters
test-mission-later-encounters: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/later-encounters-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_later_encounters.tcl
	$(PYTHON) tools/check_mission_later_encounters.py

.PHONY: test-mission-later-weapons
test-mission-later-weapons: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/later-weapons-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_later_weapons.tcl
	$(PYTHON) tools/check_mission_later_weapons.py

.PHONY: test-mission-projectiles
test-mission-projectiles: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/projectiles-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_projectiles.tcl
	$(PYTHON) tools/check_mission_projectiles.py

.PHONY: test-mission-stress
test-mission-stress: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/stress-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_stress.tcl
	$(PYTHON) tools/check_mission_stress.py

.PHONY: test-mission-crate-visibility
test-mission-crate-visibility: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/crate-visibility-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_crate_visibility.tcl
	$(PYTHON) tools/check_mission_crate_visibility.py

.PHONY: test-mission-keyboard-click
test-mission-keyboard-click: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/keyboard-click-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_keyboard_click.tcl
	$(PYTHON) -c "from pathlib import Path; assert Path('build/mission/keyboard-click-test/result.txt').read_text().strip() == '0 8'; print('OK: BIOS keyboard click remains disabled after input')"

.PHONY: test-mission-ground-hang
test-mission-ground-hang: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/ground-hang-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_ground_hang.tcl
	$(PYTHON) tools/check_mission_ground_hang.py

.PHONY: test-mission-fire-replace
test-mission-fire-replace: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/fire-replace-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_fire_replace.tcl
	$(PYTHON) -c "from pathlib import Path; assert Path('build/mission/fire-replace-test/result.txt').read_text().strip() == '0 2 2 8'; a=list(map(int,Path('build/mission/fire-replace-test/sustained.txt').read_text().split())); assert a[0]==2 and a[1]>0 and a[2:]==[2,8],a; print('OK: new bottle fire replaces previous fires and persists')"

.PHONY: test-mission-enemy-entry
test-mission-enemy-entry: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/enemy-entry-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_enemy_entry.tcl
	$(PYTHON) tools/check_mission_enemy_entry.py

.PHONY: test-mission-fire-approach
test-mission-fire-approach: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/fire-approach-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_fire_approach.tcl
	$(PYTHON) tools/check_mission_fire_approach.py

.PHONY: test-mission-fire-lifetime
test-mission-fire-lifetime: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/fire-lifetime-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_fire_lifetime.tcl
	$(PYTHON) tools/check_mission_fire_lifetime.py

.PHONY: test-mission-fixed-thrower test-mission-crate-speed
test-mission-fixed-thrower: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/fixed-thrower-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_fixed_thrower.tcl
	$(PYTHON) tools/check_mission_fixed_thrower.py

test-mission-crate-speed: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/crate-speed-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_crate_speed.tcl
	MISSION_TEST_OUT="$(CURDIR)/build/mission/crate-scroll-speed-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_crate_scroll_speed.tcl
	$(PYTHON) tools/check_mission_crate_speed.py

.PHONY: test-mission-grab-load
test-mission-grab-load: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/grab-load-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_grab_load.tcl
	$(PYTHON) tools/check_mission_grab_load.py

.PHONY: test-mission-third-crates
test-mission-third-crates: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/third-crates-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_third_crates.tcl
	$(PYTHON) tools/check_mission_third_crates.py

.PHONY: test-mission-bottle-pose
test-mission-bottle-pose: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/bottle-pose-test" "$(OPENMSX)" -machine Philips_NMS_8250 -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_bottle_pose.tcl
	$(PYTHON) tools/check_mission_bottle_pose.py

.PHONY: test-mission-ring
test-mission-ring: build-mission-visual
	MACHINE="$(MACHINE)" $(PYTHON) tools/run_mission_ring_test.py
	$(PYTHON) tools/check_mission_ring.py

# Assisted arcade investigation: changes emulated RAM only, never original ROM.
.PHONY: capture-mission-chain
capture-mission-chain:
	mkdir -p build/mission/chain-hit build/mission/chain-trace
	MISSION_CHAIN_MODE=observe COMBAT_DUMP="$(CURDIR)/build/mission/chain-trace" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/chain-trace" -autoboot_script tools/mame_mission_chain_capture.lua
	MISSION_CHAIN_MODE=hit COMBAT_DUMP="$(CURDIR)/build/mission/chain-hit" SDL_VIDEODRIVER=dummy $(MAME) combatsc -rompath "$(CURDIR)/../ARCADE/original" -video none -sound none -nothrottle -autoboot_delay 0 -snapshot_directory "$(CURDIR)/build/mission/chain-hit" -autoboot_script tools/mame_mission_chain_capture.lua
	$(PYTHON) tools/check_mission_chain_arcade.py
	$(PYTHON) tools/extract_mission_chain.py

.PHONY: test-mission-chain
test-mission-chain: build-mission-visual
	$(PYTHON) tools/run_mission_chain_test.py
	$(PYTHON) tools/check_mission_chain.py

.PHONY: test-mission-boss
test-mission-boss: build-mission-visual
	$(PYTHON) tools/run_mission_boss_test.py
	$(PYTHON) tools/check_mission_boss.py

.PHONY: capture-mission-boss
capture-mission-boss:
	mkdir -p build/mission/boss-observe build/mission/boss-hit
	COMBAT_DUMP="$(CURDIR)/build/mission/boss-observe" $(MAME) combatsc -rompath ../ARCADE/original -nothrottle -video none -sound none -autoboot_delay 0 -autoboot_script tools/mame_mission_boss_capture.lua
	COMBAT_DUMP="$(CURDIR)/build/mission/boss-hit" MISSION_BOSS_HITS=1 $(MAME) combatsc -rompath ../ARCADE/original -nothrottle -video none -sound none -autoboot_delay 0 -autoboot_script tools/mame_mission_boss_capture.lua
	$(PYTHON) tools/check_mission_boss_arcade.py
	$(PYTHON) tools/extract_mission_boss.py

.PHONY: test-mission-encounter-bounds
test-mission-encounter-bounds: build-mission-visual
	$(PYTHON) tools/run_mission_encounter_bounds_test.py

.PHONY: test-mission-pipe-ends
test-mission-pipe-ends: build-mission-visual
	$(PYTHON) tools/run_mission_pipe_ends_test.py

# PSG music: the Spectrum 128K driver in MSX RAM (tools/build_psg_music.py,
# src/psg_music.asm). The test plays the ten songs with the Spectrum's
# periods and compares every tick with ../musicPsg/regs.
.PHONY: build-psg-music test-psg-music
build-psg-music:
	$(PYTHON) tools/build_psg_music.py E000 build/psg
	$(PYTHON) tools/build_psg_arcade.py

test-psg-music:
	$(PYTHON) tools/build_psg_music.py E000 --spectrum-periods build/psg-test
	sed 's#\.\./build/psg/##' src/psg_test.asm > build/psg-test/psg_test.asm
	sed 's#\.\./build/psg/##' src/psg_music.asm > build/psg-test/psg_music.asm
	cp src/psg_calls.asm src/psg_hats.asm build/psg-test/
	$(PYTHON) tools/build_psg_arcade.py
	sed 's#\.\./build/psg/##' src/psg_arcade.asm > build/psg-test/psg_arcade.asm
	cp build/psg/arcade.inc build/psg-test/
	cd build/psg-test && sjasm psg_test.asm test.rom
	rm -rf build/psg-test/out
	PSG_OUT="$(CURDIR)/build/psg-test/out" PSG_DONE=0x$$(grep -oP '00:\K[0-9A-F]+(?=\s+\.done:)' build/psg-test/test.lst) PSG_TICKS=$$(for f in ../musicPsg/regs/0*.txt ../musicPsg/regs/11_*.txt; do grep -vc '^#' $$f; done | paste -sd,) "$(OPENMSX)" -machine $(MACHINE) -cart "$(CURDIR)/build/psg-test/test.rom" -romtype ASCII16 -script tools/test_psg_music.tcl
	$(PYTHON) tools/check_psg_music.py build/psg-test/out

.PHONY: run-rom-instructor run-rom-final
run-rom-instructor: run-step7
run-rom-final: $(RUN_ROM_DEP)
	"$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(RUN_ROM)" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_boot.tcl -script tools/run_mission_final.tcl -script tools/run_mission.tcl

.PHONY: test-step4-effects
test-step4-effects: build-step4-visual
	STEP4_EFFECTS_OUT="$(CURDIR)/build/step4/effects" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/step4/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_step4_effects.tcl
	$(PYTHON) tools/check_step4_effects.py

.PHONY: test-mission-door-sweep
test-mission-door-sweep: build-mission-visual
	MISSION_TEST_OUT="$(CURDIR)/build/mission/door-sweep-test" MISSION_LOOP=$(MISSION_LOOP_ADDR) "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/mission/visual.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/skip_mission_prelude.tcl -script tools/test_mission_door_sweep.tcl
	$(PYTHON) tools/check_mission_door_sweep.py

.PHONY: test-msx-flag-start
test-msx-flag-start: demo
	for state in 0 1; do FLAG_TEST=$$state FLAG_RESULT="$(CURDIR)/build/demo/msx-flag-$$state.txt" "$(OPENMSX)" -machine $(MACHINE) -ext gfx9000 -cart "$(CURDIR)/build/demo/demo-b1.rom" -romtype ASCII16 -script tools/run_demo.tcl -script tools/test_msx_flag_start.tcl || exit 1; test "$$(cat build/demo/msx-flag-$$state.txt)" = "$$state" || exit 1; done

MANUAL_LANGS ?= en es
MANUAL_PDFLATEX ?= pdflatex

.PHONY: manual
manual:
	$(PYTHON) tools/manual_images.py docs/manual
	mkdir -p build/manual/latex
	cd docs/manual && for lang in $(MANUAL_LANGS); do \
		for pass in 1 2; do \
			$(MANUAL_PDFLATEX) -halt-on-error -interaction=nonstopmode -output-directory=../../build/manual/latex -jobname=manual-$$lang "\def\manlang{$$lang}\input{manual}" || exit 1; \
		done; \
		cp "../../build/manual/latex/manual-$$lang.pdf" . || exit 1; \
	done
