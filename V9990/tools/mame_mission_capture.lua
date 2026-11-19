-- Capture live arcade video RAM and sprite latches in the first mission room.
-- All modes use a RAM-only setup to win the preceding fight. The course and
-- orangehit survey modes also modify mission RAM; do not use them to infer
-- collision, damage, or enemy-placement rules.
local m=manager.machine
local p=m.ioport.ports
local s=m.devices[':maincpu'].spaces['program']
local dump=dofile('tools/mame_capture_common.lua')
local action=os.getenv('MISSION_CAPTURE_ACTION') or 'movement'
local airkick_frame=tonumber(os.getenv('MISSION_AIR_FRAME') or '4790')
local course_jump_period=tonumber(os.getenv('MISSION_COURSE_JUMP_PERIOD') or '120')
local course_end=tonumber(os.getenv('MISSION_COURSE_END') or '6200')
local course_bypass=os.getenv('MISSION_COURSE_BYPASS')=='1'
local capture_hang=os.getenv('MISSION_CAPTURE_HANG')=='1'
local frame=0
local previous_world=65535
emu.register_frame_done(function()
 frame=frame+1
 if frame==300 then p[':IN0'].fields['Coin 1']:set_value(1)
 elseif frame==310 then p[':IN0'].fields['Coin 1']:set_value(0)
 elseif frame==360 then p[':IN0'].fields['1 Player Start']:set_value(1)
 elseif frame==370 then p[':IN0'].fields['1 Player Start']:set_value(0)
 elseif frame==400 then assert(s:read_u8(0x0991)==1);s:write_u8(0x0991,9)
 elseif frame==1000 then
  s:write_u8(0x0c09,s:read_u8(0x0c69)-18)
  s:write_u8(0x0c0a,0);s:write_u8(0x0c76,1)
 elseif action=='orangehit' and frame==4804 then
  -- Capture-only setup: leave the real orange object and place the player
  -- within kicking distance; remove nearby blue objects in emulated RAM.
  assert(s:read_u8(0x0d20)==0x81)
  for _,addr in ipairs({0x0c90,0x0cc0,0x0cf0}) do s:write_u8(addr,0) end
  s:write_u8(0x0d29,(s:read_u8(0x0c09)+48)&0xff)
  s:write_u8(0x0d2a,0);s:write_u8(0x0c04,184);s:write_u8(0x0c01,1)
 end
 local mission=s:read_u8(0x0991)==15 and s:read_u8(0x0990)==0
 if capture_hang and mission and frame==6100 then
  -- Exploration only: request arcade state 13, which initializes state 14.
  s:write_u8(0x0c01,0x0d)
 end
 if action=='course' and course_bypass and mission and frame>=6000 and frame%120==0 then
  -- Exploration only: move the on-screen actor past the first crate stack.
  s:write_u8(0x0c09,(s:read_u8(0x0c09)-48)&0xff)
 end
 if (action=='course' or action=='orangehit') and mission and s:read_u8(0x0c01)~=0 then
  s:write_u8(0x0c16,8)
  local state=s:read_u8(0x0c01)
  if state==16 or state==17 then s:write_u8(0x0c01,1) end
 end
 p[':IN0'].fields['P1 Button 1']:set_value(((frame>=1000 and frame<1100 and frame%4==0) or (action=='attack' and frame>=4770 and frame<4795) or (action=='airkick' and frame>=airkick_frame and frame<airkick_frame+15) or (action=='enemy' and frame>=5100 and frame<5220 and frame%30<2) or (action=='course' and mission and frame%90<2) or (action=='orangehit' and mission and ((frame<4804 and frame%90<2) or (frame>=4808 and frame%20>=8 and frame%20<10)))) and 1 or 0)
 p[':IN1'].fields['P1 Left']:set_value(((action=='movement' and frame>=4764 and frame<4820) or (action=='airkick' and frame>=4764 and frame<4820) or (action=='enemy' and frame>=5000 and frame<5002) or (action=='course' and mission) or (action=='orangehit' and mission and frame<4804)) and 1 or 0)
 p[':IN1'].fields['P1 Right']:set_value((action=='orangehit' and frame>=4804 and frame<4812) and 1 or 0)
 p[':IN0'].fields['P1 Button 2']:set_value(((action=='movement' and frame>=4824 and frame<4828) or (action=='airkick' and frame>=4780 and frame<4784) or ((action=='course' or (action=='orangehit' and frame<4804)) and mission and frame%course_jump_period<2)) and 1 or 0)
 local enemy_capture=action=='enemy' or action=='enemyattack'
 if action~='course' and ((action=='orangehit' and frame>=4800 and frame<=4900 and frame%2==0) or (action~='orangehit' and ((not enemy_capture and frame>=4760 and frame<=4860) or (enemy_capture and frame>=5080 and frame<=5240)) and frame%4==0)) then
  assert(s:read_u8(0x0991)==15 and s:read_u8(0x0990)==0)
  dump(frame)
  local f=assert(io.open(string.format('%s/frame-%04d/state.txt',os.getenv('COMBAT_DUMP'),frame),'w'))
  f:write(string.format('state=%d\nx=%d\nvertical=%d\nbuttons=%d\nedges=%d\nanim=%d\naction_flags=%d\n',s:read_u8(0x0c01),s:read_u8(0x0c09),s:read_u8(0x0c04),s:read_u8(0x0969),s:read_u8(0x096a),s:read_u8(0x0c10),s:read_u8(0x0c25)));f:close()
  local ram=assert(io.open(string.format('%s/frame-%04d/ram.bin',os.getenv('COMBAT_DUMP'),frame),'wb'))
  local bytes={}
  for addr=0x0800,0x1fff do bytes[#bytes+1]=string.char(s:read_u8(addr)) end
  ram:write(table.concat(bytes));ram:close()
 end
 if action=='course' and mission and frame>=4760 then
  local world=s:read_u8(0x09d8)*256+s:read_u8(0x09d9)
  if world>0 and world+24<=previous_world then
   dump(frame)
   local f=assert(io.open(string.format('%s/frame-%04d/world.txt',os.getenv('COMBAT_DUMP'),frame),'w'))
   f:write(world);f:close();previous_world=world
  end
 end
 if capture_hang and mission and frame>=6100 and frame<=6160 and frame%4==0 then
  dump(frame)
  local f=assert(io.open(string.format('%s/frame-%04d/hang-state.txt',os.getenv('COMBAT_DUMP'),frame),'w'))
  f:write(string.format('%d %d %d',s:read_u8(0x0c01),s:read_u8(0x0c09),s:read_u8(0x0c04)));f:close()
 end
 if frame==(action=='course' and course_end or action=='orangehit' and 4901 or enemy_capture and 5241 or 4861) then m:exit() end
end)
