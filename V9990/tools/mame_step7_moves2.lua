-- Every player move of the instructor fight, to map inputs to the arcade's
-- moves (kicks, jumps, facing). RAM shortcut to Step 7 as in
-- tools/mame_step7_moves.lua (research only), then one move every 80
-- frames from frame 1130, each a direction held and a button tapped:
-- MOVES below. The player is put back at x 60h at the start of each move;
-- the instructor (object 0C60h) is held idle (state 1) at x C0h every
-- frame, so he never interrupts a move.
-- Prints per frame: MOVE frame label state x vx sprites (num/bank/attr@x,y)
-- and dumps every 2 frames (COMBAT_DUMP) for the poses.
local m = manager.machine
local p = m.ioport.ports
local s = m.devices[':maincpu'].spaces['program']
local v1 = m.memory.shares[':videoram1']
local dump = dofile('tools/mame_capture_common.lua')
local f = function(n) return p[(n == 'b1' or n == 'b2') and ':IN0' or ':IN1'].fields[
  ({b1='P1 Button 1', b2='P1 Button 2', up='P1 Up', down='P1 Down', left='P1 Left', right='P1 Right'})[n]] end
-- {label, held directions, button, button frame offset}
local MOVES = {
  {'kick', {}, 'b1', 4},
  {'up+kick', {'up'}, 'b1', 4},
  {'down+kick', {'down'}, 'b1', 4},
  {'fwd+kick', {'right'}, 'b1', 4},
  {'back+kick', {'left'}, 'b1', 4},
  {'upfwd+kick', {'up', 'right'}, 'b1', 4},
  {'upback+kick', {'up', 'left'}, 'b1', 4},
  {'downfwd+kick', {'down', 'right'}, 'b1', 4},
  {'downback+kick', {'down', 'left'}, 'b1', 4},
  {'jump', {}, 'b2', 4},
  {'fwd+jump', {'right'}, 'b2', 4},
  {'back+jump', {'left'}, 'b2', 4},
  {'jump+kick', {}, 'b2', 4, 'b1', 16},
  {'jump+kick-late', {}, 'b2', 4, 'b1', 30},
  {'fwdjump+kick', {'right'}, 'b2', 4, 'b1', 16},
  {'backjump+kick', {'left'}, 'b2', 4, 'b1', 16},
  {'back-walk', {'left'}, nil, 0},
  {'fwd-walk', {'right'}, nil, 0},
}
local FIRST, STEP = 1130, 80
local LAST = FIRST + STEP * #MOVES
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
    local k = math.floor((frame - FIRST) / STEP) + 1
    local t = (frame - FIRST) % STEP
    local mv = (frame >= FIRST and k <= #MOVES) and MOVES[k] or nil
    if mv then
      -- Each move starts from the same place: the player at x 0x60.
      if t == 0 then s:write_u8(0x0c09, 0x60) end
      s:write_u8(0x0c61, 1)
      s:write_u8(0x0c69, 0xc0)
      if t < 50 then for _, d in ipairs(mv[2]) do held[d] = true end end
      if mv[3] and t >= mv[4] and t < mv[4] + 3 then held[mv[3]] = true end
      if mv[5] and t >= mv[6] and t < mv[6] + 3 then held[mv[5]] = true end
    end
    for _, n in ipairs({'b1','b2','up','down','left','right'}) do f(n):set_value(held[n] and 1 or 0) end
    local out = {}
    for i = 0, 63 do
      local b = 0x1800 + i * 5
      local num, bank, sy, sx, attr = v1:read_u8(b), v1:read_u8(b+1), v1:read_u8(b+2), v1:read_u8(b+3), v1:read_u8(b+4)
      if attr & 1 ~= 0 then sx = sx - 256 end
      if bank >> 4 == 1 and sx > -32 and sy < 230 then out[#out+1] = string.format('%d/%d/%02x@%d,%d', num, bank & 15, attr, sx, sy) end
    end
    print(string.format('MOVE %d %s t%d st%d x%d sprites %s', frame, mv and mv[1] or '-', t,
      s:read_u8(0x0c01), s:read_u8(0x0c09), table.concat(out, ' ')))
  end
  if frame >= FIRST and frame <= LAST and frame % 2 == 0 then dump(frame) end
  if frame == LAST + 10 then m:exit() end
end)
