-- Kick reach probe (exploration only; modifies mission RAM, not the ROM).
-- Reuses the orangehit set-up of mame_mission_capture.lua: at frame 4804 the
-- orange assailant ($0d20, X at $0d28-29) is held MISSION_KICK_DIST pixels to
-- the right of the player ($0c08-09) and the player turns right for 8 frames and kicks once at 4816.
-- Writes "<distance> <hit> <frame>": hit=1 when $0d20 leaves $81.
local m=manager.machine
local p=m.ioport.ports
local s=m.devices[':maincpu'].spaces['program']
local dist=tonumber(os.getenv('MISSION_KICK_DIST'))
local out=os.getenv('MISSION_KICK_OUT')
local frame=0
local result=nil
local function finish(text)
 local f=assert(io.open(out,'w'));f:write(text..'\n');f:close();m:exit()
end
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
 if frame==4804 then
  assert(s:read_u8(0x0d20)==0x81)
  for _,addr in ipairs({0x0c90,0x0cc0,0x0cf0}) do s:write_u8(addr,0) end
  s:write_u8(0x0c04,184);s:write_u8(0x0c01,1)
 end
 if frame>=4804 and frame<4850 and s:read_u8(0x0d20)==0x81 then
  local px=s:read_u8(0x0c08)*256+s:read_u8(0x0c09)
  local ox=px+dist
  s:write_u8(0x0d28,ox>>8);s:write_u8(0x0d29,ox&255);s:write_u8(0x0d2a,0)
 end
 if frame>4816 and frame<4850 and s:read_u8(0x0d20)~=0x81 then
  finish(string.format('%d 1 %d',dist,frame-4816))
 end
 if frame==4850 then finish(string.format('%d 0 -',dist)) end
 -- Inputs before 4804 are those of the orangehit capture.
 local early=frame<4804
 p[':IN1'].fields['P1 Right']:set_value((frame>=4804 and frame<4812) and 1 or 0)
 p[':IN1'].fields['P1 Left']:set_value((early and mission) and 1 or 0)
 p[':IN0'].fields['P1 Button 2']:set_value((early and mission and frame%120<2) and 1 or 0)
 p[':IN0'].fields['P1 Button 1']:set_value(((frame>=1000 and frame<1100 and frame%4==0) or (early and mission and frame%90<2) or (frame>=4816 and frame<4818)) and 1 or 0)
end)
