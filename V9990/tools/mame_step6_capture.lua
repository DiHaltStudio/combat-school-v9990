-- Firing range III (Step 6) capture. Loads the state "step5" saved by
-- tools/mame_step5_capture.lua, wins the arm wrestling by pressing as fast as
-- possible, then aims like tools/mame_shoot_capture.lua: the sight (circuit
-- 1, code 227) is steered to the nearest target and fires when close.
-- Dumps every 4 frames from STEP6_FIRST to STEP6_LAST (main RAM in ram.bin).
local m = manager.machine
local function field(port, name) return m.ioport.ports[port].fields[name] end
local btn1 = field(':IN0','P1 Button 1')
local up, down = field(':IN1','P1 Up'), field(':IN1','P1 Down')
local right, left = field(':IN1','P1 Right'), field(':IN1','P1 Left')
local v0, v1 = m.memory.shares[':videoram0'], m.memory.shares[':videoram1']
local mem = m.devices[':maincpu'].spaces['program']
local dump = dofile('tools/mame_capture_common.lua')
local first = tonumber(os.getenv('STEP6_FIRST') or '1700')
local last = tonumber(os.getenv('STEP6_LAST') or '5000')
local frame = 0
local function sprites(share, wanted)
  local found = {}
  for i = 0, 63 do
    local base = 0x1800 + i * 5
    local num, bank, sy, sx, attr = share:read_u8(base), share:read_u8(base+1),
      share:read_u8(base+2), share:read_u8(base+3), share:read_u8(base+4)
    if attr & 1 ~= 0 then sx = sx - 256 end
    if sx > -32 and wanted(num, bank >> 4) then found[#found+1] = {sx, sy} end
  end
  return found
end
local function aim()
  local cross = sprites(v1, function(n, c) return n == 227 and c == 2 end)[1]
  right:set_value(0); left:set_value(0); up:set_value(0); down:set_value(0)
  if not cross then btn1:set_value(0) return end
  local heads, best, bd = {}, nil, nil
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
  if frame == 2 then m:load('step5') return end
  if frame < 4 then return end
  if frame < 1500 then btn1:set_value(frame % 2) else aim() end
  if frame >= first and frame <= last and frame % 4 == 0 then
    dump(frame)
    local f = io.open(string.format('%s/frame-%04d/ram.bin', os.getenv('COMBAT_DUMP'), frame), 'wb')
    for a = 0, 0x1fff do f:write(string.char(mem:read_u8(a))) end
    f:close()
  end
  if frame >= last + 10 then m:exit() end
end)
