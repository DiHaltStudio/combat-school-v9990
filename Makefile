VERSION ?= 1.0
ROM := CombatSchool-V9990.rom
MANUAL_DIR := V9990/docs/manual
PLAYER_TARGETS := run run-demo run-shoot run-mission run-step7 run-msx-flag run-rom-instructor run-rom-final
.DEFAULT_GOAL := all

.PHONY: all rom manual release mame help clean $(PLAYER_TARGETS)
all rom:
	$(MAKE) -C V9990 rom

manual:
	$(MAKE) -C V9990 manual

$(PLAYER_TARGETS):
	$(MAKE) -C V9990 $@

mame:
	./tools/build-mame.sh

release: rom
	$(MAKE) manual
	mkdir -p release
	cp "V9990/$(ROM)" release/
	cp "$(MANUAL_DIR)/manual-en.pdf" "$(MANUAL_DIR)/manual-es.pdf" release/
	cp "$(MANUAL_DIR)/img/sticker.png" release/CombatSchool-V9990-cartridge-label.png
	cd release && zip -q -FS "CombatSchool-V9990-v$(VERSION).zip" "$(ROM)" manual-en.pdf manual-es.pdf CombatSchool-V9990-cartridge-label.png

help:
	@echo 'make          Build the MSX ROM from local original inputs'
	@echo 'make run      Open the downloaded release ROM or build and run'
	@echo 'make mame     Build the pinned MAME capture tool'
	@echo 'make manual   Build the English and Spanish PDFs and the cartridge label'
	@echo 'make release  Build and package a release (VERSION=1.0 by default)'
	@echo 'make clean    Remove generated build directories'

clean:
	rm -rf build V9990/build
	rm -f "V9990/$(ROM)"
