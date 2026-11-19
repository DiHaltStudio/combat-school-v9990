-- Which kick does button 1 give? RAM shortcut to Step 7 as in
-- tools/mame_step7_capture.lua (research only). Trials: close (instructor
-- at most 40 px away) or far (64 px or more), with no direction, up or down
-- held. Prints the player's sprite codes during each kick.
local m = manager.machine
local p = m.ioport.ports
local s = m.devices[':maincpu'].spaces['program']
local v0, v1 = m.memory.shares[':videoram0'], m.memory.shares[':videoram1']
local function fld(n) return p[(n == 'b1' or n == 'b2') and ':IN0' or ':IN1'].fields[
  ({b1='P1 Button 1', b2='P1 Button 2', up='P1 Up', down='P1 Down', left='P1 Left', right='P1 Right'})[n]] end
local function xs()
  local px, ix
  for i = 0, 63 do
    local b = 0x1800 + i * 5
    if v1:read_u8(b+1) >> 4 == 1 and v1:read_u8(b+2) < 230 then
      local x = v1:read_u8(b+3); if v1:read_u8(b+4) & 1 ~= 0 then x = x - 256 end
      if x > -32 then px = math.min(px or 999, x) end
    end
    if v0:read_u8(b+1) == 3 and v0:read_u8(b+2) < 230 then
      local x = v0:read_u8(b+3); if v0:read_u8(b+4) & 1 ~= 0 then x = x - 256 end
      if x > -32 then ix = math.min(ix or 999, x) end
    end
  end
  return px, ix
end
local trials = {{'close',nil},{'far',nil},{'close','up'},{'far','down'},{'close','down'},{'far','up'},{'close',nil},{'far',nil}}
local t, state, wait, frame, codes = 1, 'move', 0, 0, {}
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then p[':IN0'].fields['Coin 1']:set_value(1)
  elseif frame == 310 then p[':IN0'].fields['Coin 1']:set_value(0)
  elseif frame == 360 then p[':IN0'].fields['1 Player Start']:set_value(1)
  elseif frame == 370 then p[':IN0'].fields['1 Player Start']:set_value(0)
  elseif frame == 400 then s:write_u8(0x0991, 9) end
  if frame < 1100 then return end
  for _, n in ipairs({'b1','b2','up','down','left','right'}) do fld(n):set_value(0) end
  local trial = trials[t]
  if not trial or frame > 4000 then m:exit() return end
  local px, ix = xs()
  if not px or not ix then return end
  local d = ix - px
  if state == 'move' then
    if trial[1] == 'close' then
      if d > 40 then fld('right'):set_value(1) else state, wait = 'press', 6 end
    else
      if d < 64 then fld(px > 30 and 'left' or 'right'):set_value(px > 30 and 1 or 0) else state, wait = 'press', 6 end
      if d < 64 and px <= 30 then state, wait = 'press', 6 end
    end
  elseif state == 'press' then
    if trial[2] then fld(trial[2]):set_value(1) end
    wait = wait - 1
    if wait <= 2 then fld('b1'):set_value(1) end
    if wait == 0 then state, wait, codes = 'watch', 24, {} end
  elseif state == 'watch' then
    if trial[2] then fld(trial[2]):set_value(1) end
    for i = 0, 63 do
      local b = 0x1800 + i * 5
      if v1:read_u8(b+1) >> 4 == 1 and v1:read_u8(b+2) < 230 then codes[v1:read_u8(b)] = true end
    end
    wait = wait - 1
    if wait == 0 then
      local list = {}
      for c in pairs(codes) do list[#list+1] = c end
      table.sort(list)
      print(string.format('KICK %s %s dist=%d codes=%s', trial[1], trial[2] or '-', d, table.concat(list, ',')))
      t, state, wait = t + 1, 'rest', 40
    end
  elseif state == 'rest' then
    wait = wait - 1
    if wait == 0 then state = 'move' end
  end
end)
