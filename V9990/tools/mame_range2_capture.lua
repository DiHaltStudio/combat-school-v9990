-- Firing range II (Step 4) capture. Plays the first two events like
-- tools/mame_shoot_capture.lua, runs the iron man race, and once the CPU is on
-- the final straight gives the player the CPU's object (RAM 0x0c30-0x0c5f ->
-- 0x0c00) and camera (0x09ba -> 0x09da) so he reaches the goal in time. In the
-- second firing range an aiming bot steers the sight (circuit 1, code 127) to
-- the nearest target (circuit 0) and fires. Dumps the Step 3 goal and the
-- whole Step 4 every 4 frames.
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
local mem = m.devices[':maincpu'].spaces['program']
local teleported = false
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
local function aim2()
  local sight = sprites(v1, function(n, c) return n == 127 and c == 0 end)[1]
  right:set_value(0); left:set_value(0); up:set_value(0); down:set_value(0)
  if not sight then btn1:set_value(frame % 4 < 2 and 1 or 0) return end
  local best, bd
  for _, t in ipairs(sprites(v0, function(n, c) return true end)) do
    if t[2] < 180 then
      local d = math.abs(t[1] + 8 - sight[1]) + math.abs(t[2] + 8 - sight[2])
      if not bd or d < bd then best, bd = t, d end
    end
  end
  if not best then btn1:set_value(0) return end
  local dx, dy = best[1] + 8 - sight[1], best[2] + 8 - sight[2]
  if dx > 2 then right:set_value(1) elseif dx < -2 then left:set_value(1) end
  if dy > 2 then down:set_value(1) elseif dy < -2 then up:set_value(1) end
  -- Targets move: keep firing while the sight closes in.
  btn1:set_value(frame % 4 < 2 and 1 or 0)
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
  elseif frame >= 9900 then
    btn2:set_value(0); aim2()
  elseif frame >= 6200 then
    -- Iron man race: run straight up. The CPU's lane covers the course.
    right:set_value(0); left:set_value(0); down:set_value(0)
    up:set_value(1)
    btn1:set_value(frame % 8 < 4 and 1 or 0)
    btn2:set_value(0)
  else
    btn1:set_value(0); btn2:set_value(0)
  end
  -- Teleport: when the CPU is on the final straight, give its object and
  -- camera to the player so he reaches the goal in time.
  if frame > 7000 and not teleported then
    local cy = mem:read_u8(0x0c33) * 256 + mem:read_u8(0x0c34)
    if cy < 500 then
      for a = 0, 0x2f do mem:write_u8(0x0c00 + a, mem:read_u8(0x0c30 + a)) end
      mem:write_u8(0x09da, mem:read_u8(0x09ba)); mem:write_u8(0x09db, mem:read_u8(0x09bb))
      teleported = true
      print('TELEPORT', frame, cy)
    end
  end
  if frame >= 8300 and frame <= 12900 and frame % 4 == 0 then dump(frame) end
  if frame == 12910 then m:exit() end
end)
