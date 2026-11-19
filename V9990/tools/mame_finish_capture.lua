-- Same course inputs as mame_course_state.lua, continued until the player
-- reaches the goal. Dumps the bars exit and the finish ceremony densely.
local machine = manager.machine
local function field(port, name) return machine.ioport.ports[port].fields[name] end
local coin = field(':IN0', 'Coin 1')
local start = field(':IN0', '1 Player Start')
local btn1 = field(':IN0', 'P1 Button 1')
local btn2 = field(':IN0', 'P1 Button 2')
local first = tonumber(os.getenv('FINISH_FIRST') or '2340')
local last = tonumber(os.getenv('FINISH_LAST') or '3300')
local step = tonumber(os.getenv('FINISH_STEP') or '4')
local release = tonumber(os.getenv('FINISH_RELEASE') or '2790')
local frame = 0
local dump_frame = dofile('tools/mame_capture_common.lua')
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then coin:set_value(1) end
  if frame == 310 then coin:set_value(0) end
  if frame == 360 then start:set_value(1) end
  if frame == 370 then start:set_value(0) end
  if frame >= 1050 and frame < 2700 then
    btn1:set_value(frame % 8 < 4 and 1 or 0)
    btn2:set_value(frame % 90 < 3 and 1 or 0)
  elseif frame >= 2700 and frame < release then
    btn1:set_value(frame % 8 < 4 and 1 or 0)
    btn2:set_value(0)
  elseif frame >= release then
    -- Hands off once the player has crossed the goal.
    btn1:set_value(0)
    btn2:set_value(0)
  end
  if frame >= first and frame <= last and (frame - first) % step == 0 then dump_frame(frame) end
  if frame == last + 10 then machine:exit() end
end)
