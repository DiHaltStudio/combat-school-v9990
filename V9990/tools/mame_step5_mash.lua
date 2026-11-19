-- Replays Step 5 from the state saved by tools/mame_step5_capture.lua with
-- one press every COMBAT_MASH frames (0: never) and snapshots every 2 frames.
local m = manager.machine
local btn1 = m.ioport.ports[':IN0'].fields['P1 Button 1']
local mash = tonumber(os.getenv('COMBAT_MASH') or '0')
local frame = 0
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 2 then m:load('step5') return end
  if frame < 4 then return end
  if mash > 0 then btn1:set_value(frame % mash < mash // 2 and 1 or 0) else btn1:set_value(0) end
  if frame % 2 == 0 then m.video:snapshot() end
  if frame >= 1400 then m:exit() end
end)
