-- Player moves in the instructor fight. RAM shortcut to Step 7 as in
-- tools/mame_step7_capture.lua (research only), then a fixed input script:
-- kick, down+kick, up+kick, jump, down alone, both buttons, forward+kick.
-- Prints the player's sprites (circuit 1, colour 1) every frame and dumps
-- every 2 frames from 1120 to 1560.
local m = manager.machine
local p = m.ioport.ports
local s = m.devices[':maincpu'].spaces['program']
local v1 = m.memory.shares[':videoram1']
local dump = dofile('tools/mame_capture_common.lua')
local f = function(n) return p[n == 'b1' and ':IN0' or n == 'b2' and ':IN0' or ':IN1'].fields[
  ({b1='P1 Button 1', b2='P1 Button 2', up='P1 Up', down='P1 Down', left='P1 Left', right='P1 Right'})[n]] end
local script = {  -- {first, last, control}
  {1130, 1133, 'b1'},
  {1180, 1240, 'down'}, {1190, 1193, 'b1'},
  {1250, 1300, 'up'}, {1260, 1263, 'b1'},
  {1310, 1313, 'b2'},
  {1370, 1420, 'down'},
  {1440, 1443, 'b1'}, {1440, 1443, 'b2'},
  {1480, 1530, 'right'}, {1490, 1493, 'b1'},
}
local frame = 0
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then p[':IN0'].fields['Coin 1']:set_value(1)
  elseif frame == 310 then p[':IN0'].fields['Coin 1']:set_value(0)
  elseif frame == 360 then p[':IN0'].fields['1 Player Start']:set_value(1)
  elseif frame == 370 then p[':IN0'].fields['1 Player Start']:set_value(0)
  elseif frame == 400 then s:write_u8(0x0991, 9) end
  if frame >= 1100 then
    local held = {}
    for _, e in ipairs(script) do if frame >= e[1] and frame <= e[2] then held[e[3]] = true end end
    for _, n in ipairs({'b1','b2','up','down','left','right'}) do f(n):set_value(held[n] and 1 or 0) end
    local out = {}
    for i = 0, 63 do
      local b = 0x1800 + i * 5
      local num, bank, sy, sx, attr = v1:read_u8(b), v1:read_u8(b+1), v1:read_u8(b+2), v1:read_u8(b+3), v1:read_u8(b+4)
      if attr & 1 ~= 0 then sx = sx - 256 end
      if bank >> 4 == 1 and sx > -32 and sy < 230 then out[#out+1] = string.format('%d/%d/%02x@%d,%d', num, bank & 15, attr, sx, sy) end
    end
    print(string.format('MOVE %d %s', frame, table.concat(out, ' ')))
  end
  if frame >= 1120 and frame <= 1560 and frame % 2 == 0 then dump(frame) end
  if frame == 1570 then m:exit() end
end)
