-- Capture the title and the player-versus-CPU introduction from the local ROM.
local machine = manager.machine
local coin = machine.ioport.ports[':IN0'].fields['Coin 1']
local start = machine.ioport.ports[':IN0'].fields['1 Player Start']
local frame = 0
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then coin:set_value(1) end
  if frame == 310 then coin:set_value(0) end
  if frame == 360 then start:set_value(1) end
  if frame == 370 then start:set_value(0) end
  if frame >= 180 and frame <= 840 and frame % 12 == 0 then
    machine.video:snapshot()
  end
  if frame == 841 then machine:exit() end
end)
