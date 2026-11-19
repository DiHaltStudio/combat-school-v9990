-- Iron man race (Step 3) capture. Plays the first two events like
-- tools/mame_shoot_capture.lua (including its aiming bot), then runs straight
-- up in the third. The player soon gets stuck, but the CPU's camera covers the
-- whole course: river, boats, rocks, logs and goal.
local m = manager.machine
local function field(port, name) return m.ioport.ports[port].fields[name] end
local coin, start = field(':IN0','Coin 1'), field(':IN0','1 Player Start')
local btn1, btn2 = field(':IN0','P1 Button 1'), field(':IN0','P1 Button 2')
local up, down = field(':IN1','P1 Up'), field(':IN1','P1 Down')
local right, left = field(':IN1','P1 Right'), field(':IN1','P1 Left')
local v0, v1 = m.memory.shares[':videoram0'], m.memory.shares[':videoram1']
local dump = dofile('tools/mame_capture_common.lua')
local first = tonumber(os.getenv('IRONMAN_FIRST') or '6540')
local last = tonumber(os.getenv('IRONMAN_LAST') or '9200')
local step = tonumber(os.getenv('IRONMAN_STEP') or '2')
local frame = 0
local function sprites(share, wanted)
  local found = {}
  for i = 0, 63 do
    local base = 0x1800 + i * 5
    local num, bank, sy, sx, attr = share:read_u8(base), share:read_u8(base+1),
      share:read_u8(base+2), share:read_u8(base+3), share:read_u8(base+4)
    if attr & 1 ~= 0 then sx = sx - 256 end
    -- Unused entries keep old codes but sit off screen at x=-256.
    if sx > -32 and wanted(num, bank >> 4) then found[#found+1] = {sx, sy} end
  end
  return found
end
local function aim()
  local cross = sprites(v1, function(n, c) return n == 227 and c == 2 end)[1]
  right:set_value(0); left:set_value(0); up:set_value(0); down:set_value(0)
  if not cross then btn1:set_value(0) return end
  local best, bd
  -- Targets are circuit-0 sprites above the shooters; codes vary with the
  -- wave and depth, so only the screen area is used.
  local heads = {}
  for _, t in ipairs(sprites(v0, function(n, c) return c == 0 end)) do
    if t[2] < 165 and (not heads[t[1]] or t[2] < heads[t[1]][2]) then heads[t[1]] = t end
  end
  for _, t in pairs(heads) do
    local d = math.abs(t[1] - cross[1]) + math.abs(t[2] - cross[2])
    if not bd or d < bd then best, bd = t, d end
  end
  if not best then btn1:set_value(0) return end
  local dx, dy = best[1] - cross[1], best[2] - cross[2]
  if dx > 2 then right:set_value(1) elseif dx < -2 then left:set_value(1) end
  if dy > 2 then down:set_value(1) elseif dy < -2 then up:set_value(1) end
  btn1:set_value((math.abs(dx) <= 6 and math.abs(dy) <= 6 and frame % 4 < 2) and 1 or 0)
end
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 300 then coin:set_value(1) end
  if frame == 310 then coin:set_value(0) end
  if frame == 360 then start:set_value(1) end
  if frame == 370 then start:set_value(0) end
  if frame >= 1050 and frame < 2700 then
    btn1:set_value(frame % 8 < 4 and 1 or 0)
    btn2:set_value(frame % 90 < 3 and 1 or 0)
  elseif frame >= 2700 and frame < 2790 then
    btn1:set_value(frame % 8 < 4 and 1 or 0); btn2:set_value(0)
  elseif frame >= 3300 and frame < 6200 then
    btn2:set_value(0); aim()
  elseif frame >= 6200 then
    -- Iron man race: run straight up. The CPU's lane covers the course.
    right:set_value(0); left:set_value(0); down:set_value(0)
    up:set_value(1)
    btn1:set_value(frame % 8 < 4 and 1 or 0)
    btn2:set_value(0)
  else
    btn1:set_value(0); btn2:set_value(0)
  end
  if frame >= first and frame <= last and (frame - first) % step == 0 then dump(frame) end
  if frame == last + 10 then m:exit() end
end)
