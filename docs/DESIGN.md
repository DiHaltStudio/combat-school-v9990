# Cartridge design

The 2 MiB cartridge is arranged as 128 ASCII16 banks of 16 KiB. The MSX BIOS supplies the cartridge's primary slot and its subslot selection when the primary slot is expanded. The boot code maps the second ASCII16 window to the same cartridge and keeps the BIOS-selected RAM mapped.

Startup begins on the MSX video output with the credits and V9990 probe. After detection the V9990 shows the DiHalt logo, an illustrated cover and the title screen. The cover waits for a fresh keypress. The boot screens use their own bank and are skipped when a game returns to the title without restarting the machine.

The races and action stages build frames in V9990 bitmap pages. The scene, the player, opponents and the HUD are composed in the hidden page before it is displayed. The horizontal obstacle race and the vertical Iron Man race use independent views of the same course for Nick and Joe. The final mission keeps a moving window over its side-scrolling map.

The asset builders turn editable images, colour tables, trajectories and captured reference data into the format expected by each drawing routine. The cartridge combines the training events, bonus screens, instructor fight, graduation, final mission and score table. Score carries from one event to the next. The ranking stays in memory until the machine is powered off.

For entry points and memory ownership, see the comments in V9990/src/. The builder writes the cartridge bank layout to V9990/build/demo/rom-layout.txt.
