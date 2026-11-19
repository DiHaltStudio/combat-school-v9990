set throttle off
set ::out $::env(STEP4_GRID_OUT)
file mkdir $::out
after time 10 {set ::videosource GFX9000; poke 0xc809 0}
after time 10.3 {screenshot -raw "$::out/empty.png";poke 0xc809 52}
after time 10.6 {screenshot -raw "$::out/qualified.png";poke 0xc809 54}
after time 10.9 {screenshot -raw "$::out/bonus.png";exit}
