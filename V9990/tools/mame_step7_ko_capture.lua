-- Research capture of either knockout. Phase, health and starting position
-- are adjusted in RAM only; the original arcade ROM remains unchanged.
local m=manager.machine
local p=m.ioport.ports
local s=m.devices[':maincpu'].spaces['program']
local dump=dofile('tools/mame_capture_common.lua')
local loser=assert(os.getenv('STEP7_LOSER'))
assert(loser=='player' or loser=='instructor')
local last=tonumber(os.getenv('STEP7_LAST') or '1120')
local frame=0
emu.register_frame_done(function()
 frame=frame+1
 if frame==300 then p[':IN0'].fields['Coin 1']:set_value(1)
 elseif frame==310 then p[':IN0'].fields['Coin 1']:set_value(0)
 elseif frame==360 then p[':IN0'].fields['1 Player Start']:set_value(1)
 elseif frame==370 then p[':IN0'].fields['1 Player Start']:set_value(0)
 elseif frame==400 then assert(s:read_u8(0x0991)==1);s:write_u8(0x0991,9)
 elseif frame==1000 then
  if loser=='instructor' then
   local x=s:read_u8(0x0c69)-18
   s:write_u8(0x0c09,x);s:write_u8(0x0c0a,0);s:write_u8(0x0c76,1)
  else s:write_u8(0x0c16,1) end
 end
 if loser=='instructor' and frame>=1000 and frame<1100 then
  p[':IN0'].fields['P1 Button 1']:set_value(frame%4==0 and 1 or 0)
 end
 if frame>=1012 and frame<=last and frame%4==0 then dump(frame) end
 if frame==last+1 then m:exit() end
end)
