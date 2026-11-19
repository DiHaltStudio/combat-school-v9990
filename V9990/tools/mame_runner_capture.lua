-- Automated research capture; screenshots are spaced four frames apart.
local m=manager.machine
local f=0
local function field(port,name) return m.ioport.ports[port].fields[name] end
local coin=field(':IN0','Coin 1')
local start=field(':IN0','1 Player Start')
local right=field(':IN1','P1 Right')
local a=field(':IN0','P1 Button 1')
local b=field(':IN0','P1 Button 2')
emu.register_frame_done(function()
 f=f+1
 if f==300 then coin:set_value(1) elseif f==310 then coin:set_value(0) end
 if f==360 then start:set_value(1) elseif f==370 then start:set_value(0) end
 if f==1050 then right:set_value(1) end
 if f>=1050 and f<1250 then
  a:set_value((f%8)<4 and 1 or 0)
  b:set_value((f%8)>=4 and 1 or 0)
 end
 if f>=1100 and f<=1196 and f%4==0 then m.video:snapshot() end
 if f==1200 then m:exit() end
end)
