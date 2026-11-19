-- Per-frame capture of the arcade ending (frames 9000..12850): the guardian
-- falls under real kicks (only the player is positioned, as in
-- tools/mame_mission_boss_capture.lua), then the mansion, the rank screen,
-- CONGRATULATIONS and the RANKING table. ROM and guardian RAM are untouched.
local m=manager.machine
local p=m.ioport.ports
local s=m.devices[':maincpu'].spaces['program']
local dump=function() end   -- only the per-frame snapshots below
local action='course'
local hit_mode=os.getenv('MISSION_BOSS_HITS')=='1'
local airkick_frame=tonumber(os.getenv('MISSION_AIR_FRAME') or '4790')
local course_jump_period=50
local cap_from=tonumber(os.getenv('CAP_FROM') or '9000')
local cap_to=tonumber(os.getenv('CAP_TO') or '12850')
local course_end=cap_to+10
local course_bypass=true
local capture_hang=os.getenv('MISSION_CAPTURE_HANG')=='1'
local frame=0
local name_entry=os.getenv('NAME_ENTRY')=='1'
local field_up
for _,port in pairs(p) do for name,f in pairs(port.fields) do if name==(os.getenv('NAME_DIR') or 'P1 Up') then field_up=f end end end
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
  s:write_u8(0x0d2a,0);s:write_u8(0x0c04,224);s:write_u8(0x0c01,1)
 end
 local mission=s:read_u8(0x0991)==15 and s:read_u8(0x0990)==0
 if capture_hang and mission and frame==6100 then
  -- Exploration only: request arcade state 13, which initializes state 14.
  s:write_u8(0x0c01,0x0d)
 end
 if action=='course' and course_bypass and mission and frame>=6000 and frame<7200 and frame%120==0 then
  -- Exploration only: move the on-screen actor past the first crate stack.
  s:write_u8(0x0c09,(s:read_u8(0x0c09)-48)&0xff)
 end
 if (action=='course' or action=='orangehit') and mission and s:read_u8(0x0c01)~=0 then
  s:write_u8(0x0c16,8)
  local state=s:read_u8(0x0c01)
  if state==15 or state==16 or state==17 then s:write_u8(0x0c01,1) end
 end
 p[':IN0'].fields['P1 Button 1']:set_value(((frame>=1000 and frame<1100 and frame%4==0) or (action=='attack' and frame>=4770 and frame<4795) or (action=='airkick' and frame>=airkick_frame and frame<airkick_frame+15) or (action=='enemy' and frame>=5100 and frame<5220 and frame%30<2) or (action=='course' and mission and ((frame<7200 and frame%90<2) or (hit_mode and frame>=7800 and frame%60==0))) or (action=='orangehit' and mission and ((frame<4804 and frame%90<2) or (frame>=4808 and frame%20>=8 and frame%20<10)))) and 1 or 0)
 p[':IN1'].fields['P1 Left']:set_value(((action=='movement' and frame>=4764 and frame<4820) or (action=='airkick' and frame>=4764 and frame<4820) or (action=='enemy' and frame>=5000 and frame<5002) or (action=='course' and mission and frame<7570) or (action=='orangehit' and mission and frame<4804)) and 1 or 0)
 p[':IN1'].fields['P1 Right']:set_value((action=='orangehit' and frame>=4804 and frame<4812) and 1 or 0)
 p[':IN0'].fields['P1 Button 2']:set_value(((action=='movement' and frame>=4824 and frame<4828) or (action=='airkick' and frame>=4780 and frame<4784) or ((action=='course' or (action=='orangehit' and frame<4804)) and mission and frame<7200 and frame%course_jump_period<2)) and 1 or 0)
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
 if false and action=='course' and mission and frame>=4760 then
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

 if frame==7200 then
  s:write_u8(0x0c08,1);s:write_u8(0x0c09,212);s:write_u8(0x0c0a,0)
  s:write_u8(0x0c04,224);s:write_u8(0x0c01,1)
 end
 if frame>=7200 and frame<7400 then
  for a=0x0c90,0x0f90,0x30 do s:write_u8(a,0) end
 end
 if frame>=7200 then
  s:write_u8(0x0c58,0);s:write_u8(0x0c59,0)
  s:write_u8(0x0c25,s:read_u8(0x0c25)&0xfb)
 end
 if hit_mode and frame>=7799 and frame<8650 then   -- only during the fight: the ending moves the player itself
  local phase=frame%60
  -- Move only the player: start outside the boss attack range, approach
  -- during the active kick. Boss health, state and orientation are untouched.
  if phase==59 or phase==8 then
   local distance=phase==59 and 40 or 22
   local x=s:read_u8(0x0c38)*256+s:read_u8(0x0c39)+distance
   s:write_u8(0x0c08,x>>8);s:write_u8(0x0c09,x&255)
  end
 end
 -- NAME_ENTRY=1: in the RANKING, up every 12 frames through the alphabet
 -- (10470..10790), button 1 at 10800, three ups and button 1 again, then
 -- button 1 for the third letter.
 if name_entry and frame>=10460 then
  local up=(frame>=10470 and frame<10790 and frame%12<2) or (frame>=10830 and frame<10866 and frame%12<2)
  local b1=(frame>=10800 and frame<10803) or (frame>=10880 and frame<10883) or (frame>=10920 and frame<10923)
  field_up:set_value(up and 1 or 0)
  p[':IN0'].fields['P1 Button 1']:set_value(b1 and 1 or 0)
 end
 if frame>=cap_from and frame<=cap_to then m.video:snapshot() end
 if false then
  dump(frame)
  local f=assert(io.open(string.format('%s/frame-%04d/ram.bin',os.getenv('COMBAT_DUMP'),frame),'wb'))
  for a=0x0800,0x1fff do f:write(string.char(s:read_u8(a))) end
  f:close()
 end
 if frame>=(action=='course' and course_end or action=='orangehit' and 4901 or enemy_capture and 5241 or 4861) then m:exit() end
end)
