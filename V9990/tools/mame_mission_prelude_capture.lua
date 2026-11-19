-- Per-frame capture of the two arcade screens before the mission (frames
-- 3600..4900) for tools/extract_mission_prelude.py. The shortcut to the
-- mission and the setup only modify emulated RAM, not the original ROM.
local m=manager.machine
local p=m.ioport.ports
local s=m.devices[':maincpu'].spaces['program']
local frame=0
emu.register_frame_done(function()
 frame=frame+1
 if frame==300 then p[':IN0'].fields['Coin 1']:set_value(1)
 elseif frame==310 then p[':IN0'].fields['Coin 1']:set_value(0)
 elseif frame==360 then p[':IN0'].fields['1 Player Start']:set_value(1)
 elseif frame==370 then p[':IN0'].fields['1 Player Start']:set_value(0)
 elseif frame==400 then s:write_u8(0x0991,9)
 elseif frame==1000 then
  s:write_u8(0x0c09,s:read_u8(0x0c69)-18)
  s:write_u8(0x0c0a,0);s:write_u8(0x0c76,1)
 end
 p[':IN0'].fields['P1 Button 1']:set_value((frame>=1000 and frame<1100 and frame%4==0) and 1 or 0)
 if frame>=3600 and frame<=4900 then m.video:snapshot() end
 if frame==4901 then m:exit() end
end)
