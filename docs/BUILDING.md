# Building Combat School for V9990

## Tools

| Tool | Use |
|---|---|
| GNU Make 4.3 or later, SJASM 0.42c | Build the ASCII16 cartridge |
| Python 3 with Pillow and NumPy | Convert art, notes and captures |
| Git, tar and Podman | Fetch and build the pinned MAME capture executable |
| openMSX with the V9990 extension | Play the cartridge |
| pdfLaTeX, Spanish support and DejaVu Sans fonts | Rebuild the manuals and label |
| zip | Create the release archive |

## Local inputs

Put the following files at these paths relative to the repository root. They are ignored by Git. Use your own legally obtained originals.

| Local path | Contents |
|---|---|
| ARCADE/original/combatsc.zip | MAME Combat School joystick set (combatsc) |
| musicPsg/driver/bank3_pristine.bin | The 16 KiB paged bank 3 from the Spectrum 128K edition, at C000h |
| musicPsg/regs/08_castigo_y_mision.txt | Spectrum AY register stream of song 8, with the loop_tick header |

The arcade ZIP supplies 611g01.rom through 611g04.rom, 611g05.h15, 611g06.h14, 611g07.rom, 611g08.rom, 611g09.h7, 611g10.h6, 611g11.rom, 611g12.rom and ampal16l8.e7. MAME may warn about two PALs for which it has no good dump.

The Spectrum inputs can be created with the included capture helper if you own the 128K tape and the Spectrum system ROMs. This optional capture needs a full MAME installation with the spec128 driver. The local system ROM folder must contain the spec128 set with zx128_0.rom and zx128_1.rom.

    mkdir -p musicPsg/driver
    musicPsg/tools/capture.sh /path/to/your-128k.tzx /path/to/spectrum-roms build/spectrum-capture
    python3 musicPsg/tools/build_psg.py build/spectrum-capture build/spectrum-assets
    cp build/spectrum-capture/bank3_pristine.bin musicPsg/driver/
    mkdir -p musicPsg/regs
    cp build/spectrum-assets/regs/08_castigo_y_mision.txt musicPsg/regs/

## Build

    python3 -m venv V9990/build/venv
    V9990/build/venv/bin/pip install -r V9990/requirements-build.txt
    make

The build checks the local inputs before capture. Its MAME launcher fetches Debian's tag debian/0.264+dfsg.1-1, checks the commit recorded in tools/mame-revision, applies the Debian patches and builds the Combat School subset in a container. It reuses the binary in build/mame-source/ on later runs. Set MAME_JOBS=1 if the compiler needs less memory.

MAME runs the scripted capture sessions in a clean configuration. The builders convert these resources and the editable port assets, SJASM assembles the game modules, and the cartridge builder combines them into V9990/CombatSchool-V9990.rom. Captures are kept under V9990/build/ and replaced when the relevant inputs change. Set MAME to an executable explicitly when comparing another emulator installation.

## Targets

| Command | Output or action |
|---|---|
| make or make rom | Build V9990/CombatSchool-V9990.rom |
| make mame | Prepare the pinned emulator and its container |
| make run | Play release/CombatSchool-V9990.rom if present, otherwise build and play |
| make manual | Build both manuals and the printable label from the supplied sources |
| make release VERSION=1.0 | Build and package the ROM, PDFs and label in release/ |
| make help | Show the main targets |
| make clean | Remove local build directories |

The V9990 Makefile also has individual development targets for stages, capture sessions and game mechanics.
