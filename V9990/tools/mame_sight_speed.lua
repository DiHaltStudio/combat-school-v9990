-- Measures the arcade sight speed. SIGHT_STEP=2: plays the obstacle course as
-- tools/mame_shoot_capture.lua and, in the first firing range, holds each
-- direction in turn. SIGHT_STEP=6: loads the state "step5", wins the arm
-- wrestling and does the same in the third range. Prints "frame x y" of the
-- sight (circuit 1, code 227) every frame.
local m = manager.machine
local function field(port, name) return m.ioport.ports[port].fields[name] end
local coin, start = field(':IN0','Coin 1'), field(':IN0','1 Player Start')
local btn1, btn2 = field(':IN0','P1 Button 1'), field(':IN0','P1 Button 2')
local dirs = {field(':IN1','P1 Right'), field(':IN1','P1 Left'), field(':IN1','P1 Down'), field(':IN1','P1 Up')}
local v1 = m.memory.shares[':videoram1']
local step6 = os.getenv('SIGHT_STEP') == '6'
local begin = step6 and 1500 or 3400
local frame = 0
local function sight()
  for i = 0, 63 do
    local b = 0x1800 + i * 5
    local num, bank, sy, sx, attr = v1:read_u8(b), v1:read_u8(b+1), v1:read_u8(b+2), v1:read_u8(b+3), v1:read_u8(b+4)
    if num == 227 and bank >> 4 == 2 then
      if attr & 1 ~= 0 then sx = sx - 256 end
      return sx, sy
    end
  end
end
emu.register_frame_done(function()
  frame = frame + 1
  if step6 then
    if frame == 2 then m:load('step5') return end
    if frame < 4 then return end
    if frame < 1500 then btn1:set_value(frame % 2) else btn1:set_value(0) end
  else
    if frame == 300 then coin:set_value(1) end
    if frame == 310 then coin:set_value(0) end
    if frame == 360 then start:set_value(1) end
    if frame == 370 then start:set_value(0) end
    if frame >= 1050 and frame < 2700 then
      btn1:set_value(frame % 8 < 4 and 1 or 0); btn2:set_value(frame % 90 < 3 and 1 or 0)
    elseif frame >= 2700 and frame < 2790 then
      btn1:set_value(frame % 8 < 4 and 1 or 0); btn2:set_value(0)
    else btn1:set_value(0); btn2:set_value(0) end
  end
  if frame >= begin then
    local phase = (frame - begin) // 90 + 1
    for k, d in ipairs(dirs) do d:set_value((k == (phase - 1) % 4 + 1) and 1 or 0) end
    local x, y = sight()
    if x then print(string.format('SIGHT %d %d %d %d', frame, phase, x, y)) end
    if phase > 8 then m:exit() end
  end
end)
