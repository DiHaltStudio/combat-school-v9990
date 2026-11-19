-- Per-frame capture of the arcade graduation ceremony (frames 1900..2460)
-- for tools/extract_step7_ceremony.py. The shortcut and the one-hit
-- instructor setup only modify emulated RAM, not the original ROM.
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
 elseif frame==400 then assert(s:read_u8(0x0991)==1);s:write_u8(0x0991,9)
 elseif frame==1000 then
  local x=s:read_u8(0x0c69)-18
  s:write_u8(0x0c09,x);s:write_u8(0x0c0a,0);s:write_u8(0x0c76,1)
 end
 if frame>=1000 and frame<1100 then
  p[':IN0'].fields['P1 Button 1']:set_value(frame%4==0 and 1 or 0)
 end
 if frame>=1900 and frame<=2460 then m.video:snapshot() end
 if frame==2461 then m:exit() end
end)
