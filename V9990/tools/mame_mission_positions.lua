-- Enemy positions along the mission (exploration only: keeps the player's
-- health in RAM; the enemies, their spawns and the ROM are untouched).
-- The player walks left, jumping every 120 frames and kicking every 30.
-- Every 4 frames writes one line: frame, camera ($09d8), player X ($0c08),
-- then for each record $0c60..$0f30 (step $30) with bit 7 of +0 set:
-- address:flag:X(+8,+9):+$10:+$01.
-- MISSION_POS_UNBLOCK=1: if the camera stays still for 300 frames, records
-- within 160 px of the player are switched off (survey of later positions
-- only; the encounter itself is then not reproduced).
local m=manager.machine
local p=m.ioport.ports
local s=m.devices[':maincpu'].spaces['program']
local out=assert(io.open(os.getenv('MISSION_POS_OUT'),'w'))
local last=tonumber(os.getenv('MISSION_POS_END') or '9000')
local frame=0
local unblock=os.getenv('MISSION_POS_UNBLOCK')=='1'
local still,lastcam=0,-1
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
 local mission=s:read_u8(0x0991)==15 and s:read_u8(0x0990)==0
 if mission and s:read_u8(0x0c01)~=0 then
  s:write_u8(0x0c16,8)
  local state=s:read_u8(0x0c01)
  if state==16 or state==17 then s:write_u8(0x0c01,1) end
 end
 p[':IN1'].fields['P1 Left']:set_value(mission and 1 or 0)
 p[':IN0'].fields['P1 Button 2']:set_value((mission and frame%120<2) and 1 or 0)
 p[':IN0'].fields['P1 Button 1']:set_value(((frame>=1000 and frame<1100 and frame%4==0) or (mission and frame%30<2)) and 1 or 0)
 if unblock and mission then
  local cam=s:read_u8(0x09d8)*256+s:read_u8(0x09d9)
  if cam==lastcam then still=still+1 else still=0;lastcam=cam end
  if still>=300 then
   local px=s:read_u8(0x0c08)*256+s:read_u8(0x0c09)
   for a=0x0c60,0x0f30,0x30 do
    local x=s:read_u8(a+8)*256+s:read_u8(a+9)
    if s:read_u8(a)>=0x80 and math.abs(x-px)<160 then s:write_u8(a,0) end
   end
   still=0
  end
 end
 if mission and frame%4==0 then
  local line={frame,s:read_u8(0x09d8)*256+s:read_u8(0x09d9),s:read_u8(0x0c08)*256+s:read_u8(0x0c09)}
  for a=0x0c60,0x0f30,0x30 do
   local f=s:read_u8(a)
   if f>=0x80 or (f&1)==1 then
    line[#line+1]=string.format('%04x:%02x:%d:%02x:%02x',a,f,s:read_u8(a+8)*256+s:read_u8(a+9),s:read_u8(a+0x10),s:read_u8(a+1))
   end
  end
  out:write(table.concat(line,' ')..'\n')
 end
 if frame==last then out:close();m:exit() end
end)
