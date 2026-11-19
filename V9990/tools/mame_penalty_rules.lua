-- Penalty (chin-up) rules, research only.
-- PEN_SCEN=ironman  RAM shortcut 0x0991=3 at frame 400 (Step 3, mode 3), no input;
--                   logs writes of the chin-up count 0x0947 with the PC;
--                   with PEN_REST the player is held that far from the goal
--                   in frames 3500-3575.
-- PEN_SCEN=chinup   Step 1 without input, player held PEN_REST pixels from
--                   the goal at the end (as tools/mame_penalty_probe.lua);
--                   in the chin-ups (mode 0x0990=14) button 1 is pressed with
--                   period PEN_PERIOD; later, in the first firing range
--                   (mode 5) the hit counter 0x0855 is held at 0x43.
-- PEN_RAM=file appends, for every frame in modes 13 and 14, a 4-byte frame
-- number and RAM 0x0800-0x0fff.
-- Prints "S frame mode step count" on changes; snapshots every PEN_STEP
-- frames from PEN_FIRST to PEN_LAST go to COMBAT_DUMP.
local m = manager.machine
local cpu = m.devices[':maincpu']
local s = cpu.spaces['program']
local function field(port, name) return m.ioport.ports[port].fields[name] end
local coin, start = field(':IN0','Coin 1'), field(':IN0','1 Player Start')
local btn1 = field(':IN0','P1 Button 1')
local dump = dofile('tools/mame_capture_common.lua')
local scen = assert(os.getenv('PEN_SCEN'))
local period = tonumber(os.getenv('PEN_PERIOD') or '8')
local rest = tonumber(os.getenv('PEN_REST') or '5')
local first = tonumber(os.getenv('PEN_FIRST') or '99999')
local last = tonumber(os.getenv('PEN_LAST') or '8000')
local step = tonumber(os.getenv('PEN_STEP') or '20')
local frame, prev, tap, hold, ramf = 0, ''
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then coin:set_value(1) end
  if frame == 310 then coin:set_value(0) end
  if frame == 360 then start:set_value(1) end
  if frame == 370 then start:set_value(0) end
  if scen == 'ironman' and frame == 400 then
    s:write_u8(0x0991, 3)
    tap = s:install_write_tap(0x0947, 0x0947, 'count', function(off, data)
      print(string.format('W %d 0947=%02x pc=%04x x=%04x pos=%02x%02x', frame, data, cpu.state['PC'].value, cpu.state['X'].value, s:read_u8(0x0c08), s:read_u8(0x0c09))); return data end)
  end
  local mode = s:read_u8(0x0990)
  if scen == 'ironman' and os.getenv('PEN_REST') and frame == 3500 then
    local x = 0x0af0 - rest
    s:write_u8(0x0c08, x >> 8); s:write_u8(0x0c09, x & 255)
    hold = s:install_write_tap(0x0c08, 0x0c09, 'hold', function(off, data)
      if frame <= 3575 then return off == 0x0c08 and (x >> 8) or (x & 255) end
      return data end)
  end
  if scen == 'chinup' then
    if frame >= 2900 and frame <= 2975 then
      local x = 0x0af0 - rest; s:write_u8(0x0c08, x >> 8); s:write_u8(0x0c09, x & 255)
    end
    btn1:set_value((mode == 14 and frame % period < period // 2) and 1 or 0)
    if mode == 5 and frame > 3000 then s:write_u8(0x0855, 0x43) end
  end
  local now = string.format('%d %d %d', mode, s:read_u8(0x0991), s:read_u8(0x0947))
  if now ~= prev then print('S ' .. frame .. ' ' .. now); prev = now end
  if os.getenv('PEN_RAM') and (mode == 13 or mode == 14) then
    local t = {}
    for a = 0x0800, 0x0fff do t[#t+1] = string.char(s:read_u8(a)) end
    ramf = ramf or assert(io.open(os.getenv('PEN_RAM'), 'wb'))
    ramf:write(string.pack('>I4', frame)); ramf:write(table.concat(t))
  end
  if frame >= first and frame <= last and (frame - first) % step == 0 then dump(frame) end
  if frame >= last then if ramf then ramf:close() end m:exit() end
end)
