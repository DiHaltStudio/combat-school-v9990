set throttle off
set ::out $::env(STEP6_OUT)
file mkdir $::out
set ::result_seen 0
set ::bonus_seen 0
set ::interlude_seen 0
proc capture {name} {
 foreach {file device size} {vram "Sunrise GFX9000 VRAM" 524288 regs "Sunrise GFX9000 regs" 64} {
  set f [open "$::out/$name-$file.bin" w];fconfigure $f -translation binary
  puts -nonewline $f [debug read_block $device 0 $size];close $f
 }
 set ::videosource GFX9000
 screenshot -raw "$::out/$name.png"
}
after time 10 {poke 0xc736 0;poke 0xc734 50;poke 0xc75c 220;poke 0xc75d 255;poke 0xc75e 0;reg PC 0x400a}
after time 11 {
 poke 0xc434 $::env(STEP6_HITS);poke 0xc435 1
 set prev [expr {([peek 0xfc9e]+256*[peek 0xfc9f]-[peek 0xc0dd]-2)&65535}]
 poke 0xc436 [expr {$prev&255}];poke 0xc437 [expr {$prev>>8}]
}
proc watch {} {
 set stage [peek 0xc418]
 if {!$::result_seen && [peek 0xc43a]!=1} {
  set ::result_seen 1;set ::status [peek 0xc43a]
  after time 0.2 {capture result}
  if {$::env(STEP6_HITS)<32} {after time 0.5 {finish}}
 }
 if {$stage==19 && !$::bonus_seen} {
  set ::bonus_seen 1
  after time 0.2 {capture bonus}
 }
 if {$stage==20 && !$::interlude_seen} {
  set ::interlude_seen 1
  after time 0.2 {capture interlude}
  after time 0.8 {capture interlude-other}
 }
 if {$stage==18} {
  capture map
  binary scan [debug read_block "Sunrise GFX9000 regs" 18 1] cu ::page
  after frame wait_other
  return
 }
 if {[machine_info time]>35} {exit 1}
 after frame watch
}
proc wait_other {} {
 binary scan [debug read_block "Sunrise GFX9000 regs" 18 1] cu page
 if {($page&1)==($::page&1)} {after frame wait_other;return}
 capture map-other
 finish
}
proc finish {} {
 set f [open "$::out/result.txt" w]
 puts $f "$::result_seen $::status [peek 0xc418] [peek 0xc434] [peek 0xc435] [peek 0xc43f] [expr {[peek 0xc440]+256*[peek 0xc441]}] $::bonus_seen [expr {[peek 0xc75c]+256*[peek 0xc75d]+65536*[peek 0xc75e]}] $::interlude_seen"
 close $f;exit
}
after time 11.1 watch
after time 36 {exit 1}
