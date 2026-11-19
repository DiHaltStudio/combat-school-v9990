-- Read the live video state, including K007121 RAM moved out of shared
-- memory in recent MAME versions. Return a dump function for a frame number.
local machine = manager.machine
local out = assert(os.getenv('COMBAT_DUMP'), 'COMBAT_DUMP required')
local function item(device, name)
  local dev = machine.devices[device]
  local index = dev and dev.items['0/' .. name]
  return index and emu.item(index) or nil
end
local vreg = assert(item(':', 'm_vreg'), 'Missing saved item: :/m_vreg')
local controls, scrolls, sprites = {}, {}, {}
for c = 1, 2 do
  local device = ':k007121_' .. c
  controls[c] = item(device, 'm_ctrlram')
  scrolls[c] = item(device, 'm_scrollram')
  sprites[c] = item(device, 'm_sprites_buffer')
end
-- MAME 0.264 stores scroll RAM as shares and does not expose the K007121
-- control/sprite buffers as saved items. Track the same register writes and
-- sprite latch as the original capture scripts in that version. Keep taps
-- alive for the entire capture; recent versions use their live saved items.
local legacy = not (controls[1] and controls[2] and sprites[1] and sprites[2])
local regs, latched, taps = {{}, {}}, {{}, {}}, {}
if legacy then
  assert(machine.memory.shares[':scrollram0'] and machine.memory.shares[':scrollram1'],
    'Unsupported MAME: no K007121 saved items or legacy scroll RAM shares')
  local circuit = 0
  local program = machine.devices[':maincpu'].spaces['program']
  taps[1] = program:install_write_tap(0x0410, 0x0410, 'capture_bank', function(_, data)
    circuit = (data & 0x40) ~= 0 and 1 or 0
  end)
  taps[2] = program:install_write_tap(0x0000, 0x0007, 'capture_control', function(offset, data)
    regs[circuit+1][offset+1] = data
    if offset == 3 then
      local base = (data & 8) ~= 0 and 0x1000 or 0x1800
      local video = machine.memory.shares[':videoram' .. circuit]
      for i = 0, 0x7ff do latched[circuit+1][i+1] = video:read_u8(base+i) end
    end
  end)
  print('Capture: legacy K007121 write taps (MAME 0.264)')
else
  print('Capture: K007121 saved items (recent MAME)')
end
local function write_bytes(path, count, read)
  local bytes = {}
  for i = 0, count - 1 do bytes[#bytes + 1] = string.char(read(i)) end
  local f = assert(io.open(path, 'wb'))
  f:write(table.concat(bytes)); f:close()
end
return function(frame)
  -- Capture the tap handles in this closure too. Without this reference,
  -- Lua may collect them after dofile returns; MAME 0.264 can then crash
  -- while its memory views are still dispatching the callbacks.
  assert(not legacy or #taps == 2, 'Legacy capture taps were not installed')
  local dir = string.format('%s/frame-%04d', out, frame)
  assert(os.execute('mkdir -p ' .. string.format('%q', dir)))
  for _, tag in ipairs({'videoram0', 'videoram1', 'palette'}) do
    local share = assert(machine.memory.shares[':' .. tag], 'Missing shared RAM: ' .. tag)
    write_bytes(dir .. '/' .. tag .. '.bin', share.size, function(i) return share:read_u8(i) end)
  end
  local f = assert(io.open(dir .. '/registers.txt', 'w'))
  f:write(string.format('vreg=%02x\n', vreg:read(0)))
  for c = 1, 2 do
    local shared_scroll = machine.memory.shares[':scrollram' .. (c-1)]
    write_bytes(dir .. '/scrollram' .. (c-1) .. '.bin', 64, function(i)
      return shared_scroll and shared_scroll:read_u8(i) or assert(scrolls[c]):read(i)
    end)
    if legacy then
      assert(#latched[c] == 0x800, 'Sprite buffer has not yet been latched for circuit ' .. (c-1))
    end
    write_bytes(dir .. '/sprites' .. (c-1) .. '.bin', 0x800, function(i)
      return legacy and latched[c][i+1] or sprites[c]:read(i)
    end)
    f:write('ctrl' .. (c-1) .. '=')
    for i = 0, 7 do
      local value = legacy and regs[c][i+1] or controls[c]:read(i)
      assert(value, 'Control register not initialized: ' .. (c-1) .. '/' .. i)
      f:write(string.format('%02x ', value))
    end
    f:write('\n')
  end
  f:close()
  machine.video:snapshot()
  print('Captured frame', frame)
end
