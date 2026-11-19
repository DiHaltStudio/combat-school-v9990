-- Every frame of the title and the player-versus-CPU introduction (INTRO_FIRST..INTRO_LAST).
local machine = manager.machine
local coin = machine.ioport.ports[':IN0'].fields['Coin 1']
local start = machine.ioport.ports[':IN0'].fields['1 Player Start']
local frame = 0
local first = tonumber(os.getenv("INTRO_FIRST") or "180")
local last = tonumber(os.getenv("INTRO_LAST") or "840")
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then coin:set_value(1) end
  if frame == 310 then coin:set_value(0) end
  if frame == 360 then start:set_value(1) end
  if frame == 370 then start:set_value(0) end
  if frame >= first and frame <= last then
    machine.video:snapshot()
  end
  if frame >= last + 1 then machine:exit() end
end)
