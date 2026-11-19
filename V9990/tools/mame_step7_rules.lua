-- Instructor fight rules, research only (RAM shortcut 0x0991=9 as in
-- tools/mame_step7_capture.lua). STEP7_SCENARIO:
--   intro    no input; dumps every 4 frames 400..1100 (READY and labels)
--   timeout  both healths (0x0c16 player, 0x0c76 instructor) kept at 8;
--            dumps every 20 frames until 6000 (clock running out)
--   stand    no input, player health refilled; logs hits
--   crouch   down held; logs hits
--   jump     button 2 pressed whenever on the ground next to the instructor
--   jumpkick as jump, with button 1 pressed 6 frames after taking off
-- Prints "R frame playerHP cpuHP playerState cpuState playerX cpuX player:codes cpu:codes".
local m = manager.machine
local p = m.ioport.ports
local s = m.devices[':maincpu'].spaces['program']
local v0, v1 = m.memory.shares[':videoram0'], m.memory.shares[':videoram1']
local dump = dofile('tools/mame_capture_common.lua')
local scen = assert(os.getenv('STEP7_SCENARIO'))
local function fld(n) return p[(n == 'b1' or n == 'b2') and ':IN0' or ':IN1'].fields[
  ({b1='P1 Button 1', b2='P1 Button 2', up='P1 Up', down='P1 Down', left='P1 Left', right='P1 Right'})[n]] end
local function codes(share, want)
  local out = {}
  for i = 0, 63 do
    local b = 0x1800 + i * 5
    local num, bank, sy, sx, attr = share:read_u8(b), share:read_u8(b+1), share:read_u8(b+2), share:read_u8(b+3), share:read_u8(b+4)
    if attr & 1 ~= 0 then sx = sx - 256 end
    if want(bank) and sx > -32 and sy < 230 then out[#out+1] = string.format('%d/%02x@%d,%d', num, attr, sx, sy) end
  end
  return table.concat(out, ' ')
end
local frame = 0
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then p[':IN0'].fields['Coin 1']:set_value(1)
  elseif frame == 310 then p[':IN0'].fields['Coin 1']:set_value(0)
  elseif frame == 360 then p[':IN0'].fields['1 Player Start']:set_value(1)
  elseif frame == 370 then p[':IN0'].fields['1 Player Start']:set_value(0)
  elseif frame == 400 then s:write_u8(0x0991, 9) end
  if frame < 400 then return end
  for _, n in ipairs({'b1','b2','up','down','left','right'}) do fld(n):set_value(0) end
  if scen == 'timeout' and frame > 1000 then s:write_u8(0x0c16, 8); s:write_u8(0x0c76, 8) end
  if (scen == 'stand' or scen == 'crouch' or scen == 'jump' or scen == 'jumpkick') and frame > 1000 and s:read_u8(0x0c16) < 3 then s:write_u8(0x0c16, 8) end
  if scen == 'crouch' and frame > 1000 then fld('down'):set_value(1) end
  if (scen == 'jump' or scen == 'jumpkick') and frame > 1000 and s:read_u8(0x0c01) == 1 and frame % 30 == 0 then fld('b2'):set_value(1) end
  if scen == 'jumpkick' and frame > 1000 and s:read_u8(0x0c01) == 2 and frame % 30 >= 6 and frame % 30 < 9 then fld('b1'):set_value(1) end
  if (scen == 'jump' or scen == 'jumpkick') and frame > 1000 and s:read_u8(0x0c76) < 3 then s:write_u8(0x0c76, 8) end
  print(string.format('R %d %d %d %d %d %d %d p:%s c:%s', frame, s:read_u8(0x0c16), s:read_u8(0x0c76), s:read_u8(0x0c01), s:read_u8(0x0c61), s:read_u8(0x0c09), s:read_u8(0x0c69),
    codes(v1, function(b) return b >> 4 == 1 end), codes(v0, function(b) return b == 3 end)))
  if scen == 'intro' and frame <= 1100 and frame % 4 == 0 then dump(frame) end
  if scen == 'timeout' and frame >= 1000 and frame % 20 == 0 then dump(frame) end
  local last = ({intro=1100, timeout=6200, stand=3000, crouch=3000, jump=3000, jumpkick=3000})[scen]
  if frame >= last then m:exit() end
end)
