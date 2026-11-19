-- Research-only RAM shortcut to the instructor fight; original ROM untouched.
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
 end
 if frame>=1060 and frame<1160 then p[':IN0'].fields['P1 Button 1']:set_value(frame%20<3 and 1 or 0) end
 if frame==1160 then p[':IN0'].fields['P1 Button 1']:set_value(0) end
 if frame>=1200 and frame<1280 then p[':IN0'].fields['P1 Button 2']:set_value(frame%30<3 and 1 or 0) end
 if frame==1024 or frame==1050 or frame==1070 or frame==1090 or frame==1210 or frame==1230 then
  assert(s:read_u8(0x0990)==7 and s:read_u8(0x0991)==10)
  dump(frame)
 end
 if frame==1240 then m:exit() end
end)
