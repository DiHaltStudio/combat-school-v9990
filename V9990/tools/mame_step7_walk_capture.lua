-- Record actual arcade walking poses after the same RAM-only phase shortcut.
local m=manager.machine
local p=m.ioport.ports
local s=m.devices[':maincpu'].spaces['program']
local dump=dofile('tools/mame_capture_common.lua')
local frame=0
emu.register_frame_done(function()
 frame=frame+1
 if frame==300 then p[':IN0'].fields['Coin 1']:set_value(1)
 elseif frame==310 then p[':IN0'].fields['Coin 1']:set_value(0)
 elseif frame==360 then p[':IN0'].fields['1 Player Start']:set_value(1)
 elseif frame==370 then p[':IN0'].fields['1 Player Start']:set_value(0)
 elseif frame==400 then assert(s:read_u8(0x0991)==1);s:write_u8(0x0991,9)
 elseif frame==960 then p[':IN1'].fields['P1 Left']:set_value(1)
 end
 if frame>=960 and frame<=1004 and frame%4==0 then
  assert(s:read_u8(0x0990)==7 and s:read_u8(0x0991)==10)
  dump(frame)
 end
 if frame==1005 then m:exit() end
end)
