-- Capture synchronized video RAM, scroll RAM, palette and screenshots.
local out = assert(os.getenv('COMBAT_DUMP'), 'COMBAT_DUMP required')
local machine = manager.machine
local function field(port, name) return machine.ioport.ports[port].fields[name] end
local coin = field(':IN0', 'Coin 1')
local start = field(':IN0', '1 Player Start')
local right = field(':IN1', 'P1 Right')
local left = field(':IN1', 'P1 Left')
local btn1 = field(':IN0', 'P1 Button 1')
local btn2 = field(':IN0', 'P1 Button 2')
local frame = 0
local dump_frame = dofile('tools/mame_capture_common.lua')
local function dump() dump_frame(frame) end

emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then coin:set_value(1) end
  if frame == 310 then coin:set_value(0) end
  if frame == 360 then start:set_value(1) end
  if frame == 370 then start:set_value(0) end
  if frame >= 1050 and frame < 2700 then
    btn1:set_value(frame % 8 < 4 and 1 or 0)
    btn2:set_value(frame % 90 < 3 and 1 or 0)
  end
  if frame >= 1680 and frame <= 1820 then dump() end
  if frame == 1821 then machine:exit() end
end)
