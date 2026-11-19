-- Combat School (ZX Spectrum 128K, Ocean 1987): capture of the AY music, song by song (doc/analisis_driver.md).
-- Run through tools/capture.sh. MAME loads the real tape (SpeedLock 3), then at frame READY_FRAME, with the driver in bank 3 still
-- untouched, this script keeps a copy of bank 3 and, for each song / effect: restores it, starts the item through the game's own
-- entries (9F51h song, 9F6Ah effect) from a stub at 5B00h and ticks the driver once per frame (as the menu does, 9C70h).
-- A tick ends when R0 is written (the driver writes R12 or R13 .. R0 in order). The loop point is exact: the first tick whose driver
-- state (below) was already seen. Output CAP_DIR/<song|sfx>NN.txt: header, then one line per tick: 14 hex register values and an R13
-- written flag (a write to R13 restarts the envelope, so it must not be lost).
local m = manager.machine
local cpu = m.devices[":maincpu"]
local iosp, prog = cpu.spaces["io"], cpu.spaces["program"]
local capdir = os.getenv("CAP_DIR") or "."
local READY_FRAME = tonumber(os.getenv("READY_FRAME") or "26130")
local MAX_TICKS = tonumber(os.getenv("MAX_TICKS") or "50000")
local STUB = 0x5B00

local items = {}
for n = 0, 9 do items[#items + 1] = { kind = "song", n = n, entry = 0x9F51, max = MAX_TICKS } end
for n = 0, tonumber(os.getenv("SFX_LAST") or "19") do items[#items + 1] = { kind = "sfx", n = n, entry = 0x9F6A, max = 1500 } end

local frame, cur, idx, reg = 0, nil, 0, 0
local regs, r13w = {}, 0
for i = 0, 15 do regs[i] = 0 end
local bank3 = nil

local function page(b) iosp:write_u8(0x7ffd, b) end

local function state_key()
  local t = { prog:read_u8(0xC013), prog:read_u8(0xC021), prog:read_u8(0xC2B7), prog:read_u8(0xC348), prog:read_u8(0xC183) }
  for a = 0xC35C, 0xC3B1 do t[#t + 1] = prog:read_u8(a) end
  return string.char(table.unpack(t))
end

local function save_item()
  local it = cur
  local name = string.format("%s/%s%02d.txt", capdir, it.kind, it.n)
  local f = io.open(name, "w")
  f:write(string.format("%s %d end=%s loop_start=%d loop_len=%d ticks=%d\n", it.kind, it.n, it.ended and "stop" or (it.loop_start and "loop" or "max"),
    it.loop_start or -1, it.loop_len or 0, #it.ticks))
  f:write(table.concat(it.ticks, "\n")); f:write("\n"); f:close()
  print(string.format("%s %d: %d ticks, %s loop_start=%s loop_len=%s", it.kind, it.n, #it.ticks, it.ended and "stop" or "", tostring(it.loop_start), tostring(it.loop_len)))
end

local function start_next()
  idx = idx + 1
  cur = items[idx]
  if not cur then m:exit(); return end
  cur.ticks, cur.seen, cur.tail = {}, {}, nil
  page(3)
  for i = 1, #bank3 do prog:write_u8(0xBFFF + i, bank3:byte(i)) end
  page(0)
  local e = cur.entry
  local code = { 0x00, 0x00, 0xF3, 0x31, 0xFF, 0xBF, 0x3E, cur.n, 0xCD, e & 255, e >> 8 }
  local loop = STUB + #code
  for _, b in ipairs({ 0xFB, 0x76, 0xF3, 0x01, 0xFD, 0x7F, 0x3E, 0x03, 0xED, 0x79, 0xCD, 0x00, 0xC0, 0x01, 0xFD, 0x7F, 0xAF, 0xED, 0x79, 0x18, 0xEB }) do code[#code + 1] = b end
  for i, b in ipairs(code) do prog:write_u8(STUB + i - 1, b) end
  regs[13] = 0
  cpu.state["PC"].value = STUB
end

local function tick_end()
  local it = cur
  if not it or it.done then return end
  local s = {}
  for i = 0, 13 do s[#s + 1] = string.format("%02X", regs[i]) end
  it.ticks[#it.ticks + 1] = table.concat(s, " ") .. " " .. r13w
  r13w = 0
  local n = #it.ticks
  local playing = (it.kind == "song") and prog:read_u8(0xC002) or prog:read_u8(0xC042)
  if it.tail then
    it.tail = it.tail - 1
    if it.tail <= 0 then it.done = true end
    return
  end
  if playing == 0 then it.ended = true; it.tail = 3; return end
  if it.kind == "song" and not it.loop_start then
    local k = state_key()
    if it.seen[k] then
      it.loop_start = it.seen[k]; it.loop_len = n - it.seen[k]
      it.tail = it.loop_len + 2   -- one more whole loop: build_psg.py checks that it repeats register by register
    else it.seen[k] = n end
  end
  if n >= it.max then it.done = true end
end

tap = iosp:install_write_tap(0x0000, 0xffff, "ay", function(off, data, mask)
  if off & 0x8002 ~= 0x8000 then return end
  if off & 0x4000 ~= 0 then reg = data & 0x0f
  else
    regs[reg] = data
    if reg == 13 then r13w = 1 end
    if reg == 0 then tick_end() end
  end
end)

local enter = m.ioport.ports[":LINE6"].fields["ENTER"]
local cass = m.cassettes[":cassette"]
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 200 then enter:set_value(1) end
  if frame == 206 then enter:set_value(0); cass:play() end
  if frame == READY_FRAME then
    page(3)
    local t = {}
    for a = 0xC000, 0xFFFF do t[#t + 1] = string.char(prog:read_u8(a)) end
    page(0)
    bank3 = table.concat(t)
    print(string.format("ready: tape %.1f/%.1f s; C000: %02X %02X %02X, C002=%02X", cass.position, cass.length, bank3:byte(1), bank3:byte(2), bank3:byte(3), bank3:byte(3)))
    local f = io.open(capdir .. "/bank3_pristine.bin", "wb"); f:write(bank3); f:close()
    start_next()
    cur.start_frame = frame
  elseif frame > READY_FRAME and cur and cur.done then
    save_item()
    start_next()
    if cur then cur.start_frame = frame end
  elseif frame > READY_FRAME and cur and #cur.ticks == 0 and frame - cur.start_frame > 200 then
    print(string.format("watchdog: %s %d produced no ticks, PC=%04X", cur.kind, cur.n, cpu.state["PC"].value))
    m:exit()
  end
end)
