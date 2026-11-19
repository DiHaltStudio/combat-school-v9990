#!/usr/bin/env python3
"""Combat School (ZX Spectrum 128K): from the captures of capture_ay.lua to the songs in musicPsg/.
usage: build_psg.py <capture dir> <musicPsg dir>
For each song / effect: checks that the captured loop repeats register by register, writes <name>.vgm (AY at the Spectrum's clock,
registers as the driver wrote them), msx/<name>.vgm (periods rescaled for the MSX PSG clock, so it sounds in the same key; R7 bits 7-6 = 10,
the safe value for the MSX PSG I/O ports), regs/<name>.txt (one line per tick) and informe.md (duration, loop, range, noise)."""
import math, os, struct, sys

ZX_CLOCK = 1773450            # 3546900 / 2 Hz (Spectrum 128K, MAME spec128)
MSX_CLOCK = 1789773           # 3579545 / 2 Hz
TICK_HZ = 3546900 / 70908     # a tick per frame of 70908 T-states: 50.02 Hz
VGM_RATE = 44100
NOTE = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
SONGS = {0: "00_graduacion", 1: "01_player_ready", 2: "02_carrera_obstaculos", 3: "03_galeria_de_tiro",
         4: "04_iron_man", 5: "05_arm_wrestling", 6: "06_ranking", 7: "07_menu_y_pelea",
         8: "08_castigo_y_mision", 9: "09_bonus"}
SFX = {0: "pelea_cod", 2: "disparo", 3: "impacto", 4: "impacto_tanques_cod", 8: "pelea_cod", 9: "aviso_cuenta_atras", 10: "fin_de_tiempo", 13: "golpe_pelea"}
MASK = [0xFF, 0x0F, 0xFF, 0x0F, 0xFF, 0x0F, 0x1F, 0x3F, 0x1F, 0x1F, 0x1F, 0xFF, 0xFF, 0x0F]


def read_capture(path):
    with open(path) as f:
        head = f.readline().split()
        meta = dict(x.split("=") for x in head[2:])
        ticks = []
        for line in f:
            v = line.split()
            ticks.append(([int(x, 16) & m for x, m in zip(v[:14], MASK)], int(v[14])))
    return head[0], int(head[1]), meta, ticks


def to_msx(regs):
    r = list(regs)
    k = MSX_CLOCK / ZX_CLOCK
    for lo in (0, 2, 4):
        p = min(0xFFF, round((r[lo] | r[lo + 1] << 8) * k))
        r[lo], r[lo + 1] = p & 255, p >> 8
    r[6] = min(31, round(r[6] * k))
    e = min(0xFFFF, round((r[11] | r[12] << 8) * k))
    r[11], r[12] = e & 255, e >> 8
    return r


def gd3(title):
    fields = [title, "", "Combat School", "", "ZX Spectrum 128K", "", "Jas. C. Brooke", "", "1987", "tools/build_psg.py", ""]
    data = b"".join(f.encode("utf-16-le") + b"\0\0" for f in fields)
    return b"Gd3 " + struct.pack("<II", 0x100, len(data)) + data


def vgm(ticks, loop_at, clock, title, msx):
    """ticks [(regs, R13 written)]; loop_at: tick the loop goes back to (None: no loop). Only changes are written, except R13 (a write restarts the envelope)."""
    body, prev, now, loop_body, loop_now = bytearray(), [None] * 14, 0, None, 0
    for i, (regs, r13w) in enumerate(ticks):
        if i == loop_at:
            loop_body, loop_now = len(body), now
        if msx:
            regs = to_msx(regs)
        for r in range(13):
            v = regs[r] | 0x80 if r == 7 and msx else regs[r]
            if v != prev[r]:
                body += bytes([0xA0, r, v])
                prev[r] = v
        if r13w:
            body += bytes([0xA0, 13, regs[13]])
        end = round((i + 1) * VGM_RATE / TICK_HZ)
        wait = end - now
        now = end
        while wait > 0:
            n = min(wait, 65535)
            body += b"\x61" + struct.pack("<H", n)
            wait -= n
    body += b"\x66"
    tag = gd3(title)
    hdr = bytearray(0x100)
    hdr[0:4] = b"Vgm "
    struct.pack_into("<I", hdr, 0x08, 0x161)
    struct.pack_into("<I", hdr, 0x14, 0x100 + len(body) - 0x14)
    struct.pack_into("<I", hdr, 0x18, now)
    if loop_body is not None:
        struct.pack_into("<I", hdr, 0x1C, 0x100 + loop_body - 0x1C)
        struct.pack_into("<I", hdr, 0x20, now - loop_now)
    struct.pack_into("<I", hdr, 0x24, 50)
    struct.pack_into("<I", hdr, 0x34, 0x100 - 0x34)
    struct.pack_into("<I", hdr, 0x74, clock)
    hdr[0x79] = 0x01
    out = bytearray(bytes(hdr) + bytes(body) + tag)
    struct.pack_into("<I", out, 0x04, len(out) - 4)
    return bytes(out)


def note(period):
    if not period:
        return None
    return round(69 + 12 * math.log2(ZX_CLOCK / (16 * period) / 440))


def nname(n):
    return f"{NOTE[n % 12]}{n // 12 - 1}"


def main():
    cap, out = sys.argv[1:3]
    for d in ("msx", "regs", "sfx/msx"):
        os.makedirs(os.path.join(out, d), exist_ok=True)
    rows = []
    for n in range(10):
        kind, _, meta, ticks = read_capture(f"{cap}/song{n:02d}.txt")
        name = SONGS[n]
        ls, ll = int(meta["loop_start"]), int(meta["loop_len"])
        if meta["end"] == "loop":
            tail = ticks[ls + ll:]
            again = ticks[ls:ls + len(tail)]
            if tail != again or len(tail) < ll:
                sys.exit(f"{name}: the loop does not repeat")
            use, loop = ticks[:ls + ll], ls
        else:
            use, loop = ticks, None
        title = f"Combat School 128K - {name}"
        open(f"{out}/{name}.vgm", "wb").write(vgm(use, loop, ZX_CLOCK, title, False))
        open(f"{out}/msx/{name}.vgm", "wb").write(vgm(use, loop, MSX_CLOCK, title + " (MSX PSG)", True))
        with open(f"{out}/regs/{name}.txt", "w") as f:
            f.write(f"# R0..R13 + R13 written, one line per tick ({TICK_HZ:.2f} Hz); ticks={len(use)} loop_tick={loop if loop is not None else '-'}\n")
            for regs, w in use:
                f.write(" ".join(f"{v:02X}" for v in regs) + f" {w}\n")
        chans = []
        for c in range(3):
            notes, on = [], 0
            for regs, _ in use:
                if not regs[7] >> c & 1 and regs[8 + c] & 0x1F:
                    on += 1
                    notes.append(note(regs[c * 2] | regs[c * 2 + 1] << 8))
            notes = [x for x in notes if x is not None]
            chans.append(f"{nname(min(notes))}-{nname(max(notes))}" if notes else "-")
        noise = sum(1 for regs, _ in use if any(not regs[7] >> (3 + c) & 1 and regs[8 + c] & 0x1F for c in range(3))) * 100 // len(use)
        env = sum(1 for regs, _ in use if any(regs[8 + c] & 0x10 for c in range(3)))
        rows.append((name, len(use) / TICK_HZ, loop / TICK_HZ if loop is not None else None, chans, noise, env))
    effects = 0
    for n in range(20):
        _, _, _, ticks = read_capture(f"{cap}/sfx{n:02d}.txt")
        name = f"sfx_{n:02d}_{SFX.get(n, 'sin_uso')}"
        open(f"{out}/sfx/{name}.vgm", "wb").write(vgm(ticks, None, ZX_CLOCK, f"Combat School 128K - {name}", False))
        open(f"{out}/sfx/msx/{name}.vgm", "wb").write(vgm(ticks, None, MSX_CLOCK, f"Combat School 128K - {name} (MSX PSG)", True))
        effects += 1
    with open(f"{out}/informe.md", "w") as f:
        f.write("| Canción | Duración | Bucle desde | Canal A | Canal B | Canal C | Ruido | Envolvente |\n|---|---|---|---|---|---|---|---|\n")
        for name, dur, lp, ch, noise, env in rows:
            f.write(f"| {name} | {dur:.2f} s | {f'{lp:.2f} s' if lp is not None else 'sin bucle'} | {ch[0]} | {ch[1]} | {ch[2]} | {noise} % | {'sí' if env else 'no'} |\n")
    print(open(f"{out}/informe.md").read(), f"{effects} effects")


if __name__ == "__main__":
    main()
