# Run the machine for DV_SECONDS emulated seconds, stop it, and dump V9990 VRAM/registers/palette and the TMS VRAM.
# Env: DV_OUT (dir), DV_SECONDS (default 12). Requires the gfx9000 extension. Read only while stopped (reference doc 9).
set ::out $::env(DV_OUT)
file mkdir $::out
set throttle off
set ::secs [expr {[info exists ::env(DV_SECONDS)] ? $::env(DV_SECONDS) : 12}]
proc save {name data} { set h [open $::out/$name w]; fconfigure $h -translation binary; puts -nonewline $h $data; close $h }
proc tick {} {
    if {[machine_info time] >= $::secs} {
        debug break
        save v9_vram.bin [debug read_block "Sunrise GFX9000 VRAM" 0 524288]
        save v9_regs.bin [debug read_block "Sunrise GFX9000 regs" 0 64]
        save v9_pal.bin [debug read_block "Sunrise GFX9000 palette" 0 256]
        save tms_vram.bin [debug read_block "physical VRAM" 0 16384]
        set mem [debug read_block memory 0 65536]
        set regs [debug read_block "Sunrise GFX9000 regs" 0 64]
        binary scan [string index $regs 18] c display_reg
        set shadow [expr {0xc100 + (($display_reg & 1) * 256)}]
        set published [string range $mem $shadow [expr {$shadow + 255}]]
        set mem [string replace $mem 0xc000 0xc0ff $published]
        save ram.bin $mem
        exit
    }
    after frame tick
}
after frame tick
