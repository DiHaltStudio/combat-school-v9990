-- A step lost far from the goal (no penalty): Step 1 without input. One
-- snapshot every LOST_STEP frames from LOST_FIRST to LOST_LAST, to see the
-- arcade's messages before GAME OVER (make capture-lost).
local m = manager.machine
local function field(port, name) return m.ioport.ports[port].fields[name] end
local coin, start = field(':IN0','Coin 1'), field(':IN0','1 Player Start')
local first = tonumber(os.getenv('LOST_FIRST') or '2900')
local last = tonumber(os.getenv('LOST_LAST') or '4400')
local step = tonumber(os.getenv('LOST_STEP') or '6')
local frame = 0
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then coin:set_value(1) end
  if frame == 310 then coin:set_value(0) end
  if frame == 360 then start:set_value(1) end
  if frame == 370 then start:set_value(0) end
  if frame >= first and frame <= last and (frame - first) % step == 0 then m.video:snapshot() end
  if frame >= last + 1 then m:exit() end
end)
