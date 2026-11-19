-- Penalty (chin-up) research. Step 1 played by pressing button 1 with period
-- PEN_PERIOD frames (0 = no presses) and jumping every 90 frames, then no
-- input. PEN_REST (pixels) holds the player position 0x0c08 at the goal
-- 0x0af0 minus that distance in frames 2900-2975, before the clock ends.
-- Prints "S frame b0990 b0991" when those bytes change and dumps a
-- snapshot every PEN_STEP frames from PEN_FIRST to PEN_LAST.
local m = manager.machine
local function field(port, name) return m.ioport.ports[port].fields[name] end
local coin, start = field(':IN0','Coin 1'), field(':IN0','1 Player Start')
local btn1, btn2 = field(':IN0','P1 Button 1'), field(':IN0','P1 Button 2')
local s = m.devices[':maincpu'].spaces['program']
local dump = dofile('tools/mame_capture_common.lua')
local period = tonumber(os.getenv('PEN_PERIOD') or '0')
local first = tonumber(os.getenv('PEN_FIRST') or '1000')
local last = tonumber(os.getenv('PEN_LAST') or '6000')
local step = tonumber(os.getenv('PEN_STEP') or '60')
local frame, prev = 0, ''
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then coin:set_value(1) end
  if frame == 310 then coin:set_value(0) end
  if frame == 360 then start:set_value(1) end
  if frame == 370 then start:set_value(0) end
  local b1, b2 = 0, 0
  if frame >= 1050 and frame < 2790 and period > 0 then
    b1 = (frame % period < period // 2) and 1 or 0
    b2 = (frame % 90 < 3) and 1 or 0
  end
  btn1:set_value(b1); btn2:set_value(b2)
  local rest = tonumber(os.getenv('PEN_REST') or '-1')
  if rest >= 0 and frame >= 2900 and frame <= 2975 then
    local x = 0x0af0 - rest; s:write_u8(0x0c08, x >> 8); s:write_u8(0x0c09, x & 255)
  end
  local now = string.format('%d %d res=%d count=%d', s:read_u8(0x0990), s:read_u8(0x0991), s:read_u8(0x0a6e), s:read_u8(0x0947))
  if now ~= prev then print('S ' .. frame .. ' ' .. now); prev = now end
  if frame >= first and frame <= last and (frame - first) % step == 0 then dump(frame) end
  if frame >= last then m:exit() end
end)
