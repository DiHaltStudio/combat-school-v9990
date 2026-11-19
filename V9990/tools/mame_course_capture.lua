-- Capture the first course with repeated run pulses. Fails at obstacles without jumping.
local m=manager.machine
local function field(port,name) return m.ioport.ports[port].fields[name] end
local coin=field(':IN0','Coin 1')
local start=field(':IN0','1 Player Start')
local run=field(':IN0','P1 Button 1')
local jump=field(':IN0','P1 Button 2')
local f=0
emu.register_frame_done(function()
 f=f+1
 if f==300 then coin:set_value(1) elseif f==310 then coin:set_value(0) end
 if f==360 then start:set_value(1) elseif f==370 then start:set_value(0) end
 if f>=1050 and f<3000 then
  run:set_value(f%8<4 and 1 or 0)
  -- Repeated jumps are a simple exploratory input, not an optimal replay.
  jump:set_value(f%90<3 and 1 or 0)
 end
 if f>=1080 and f<=2700 and f%15==0 then m.video:snapshot() end
 if f==2710 then m:exit() end
end)
