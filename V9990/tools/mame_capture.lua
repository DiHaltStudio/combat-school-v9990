-- Capture synchronized video RAM, scroll RAM, palette and screenshots.
local out = assert(os.getenv('COMBAT_DUMP'), 'COMBAT_DUMP required')
local machine = manager.machine
local function field(port, name) return machine.ioport.ports[port].fields[name] end
local coin = field(':IN0', 'Coin 1')
local start = field(':IN0', '1 Player Start')
local frame = 0
local dump_frame = dofile('tools/mame_capture_common.lua')
local function dump() dump_frame(frame) end

emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then coin:set_value(1) end
  if frame == 310 then coin:set_value(0) end
  if frame == 360 then start:set_value(1) end
  if frame == 370 then start:set_value(0) end
  if frame == 600 or frame == 900 or frame == 1200 or frame == 1500 then dump() end
  if frame == 1500 then machine:exit() end
end)
