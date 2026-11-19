set throttle off
set out $::env(MISSION_TEST_OUT)
file mkdir $out
proc sample {name} {
 set f [open "$::out/$name.txt" w]
 puts $f "[expr {[peek 0xc852]+256*[peek 0xc853]-768}] [peek 0xc856] [peek 0xc8d4]"
 close $f
}
proc setup {x} {
 poke 0xc840 0;poke 0xc841 3;poke 0xc800 0;poke 0xc801 88
 poke 0xc851 1;poke 0xc852 $x;poke 0xc853 3;poke 0xc855 0
 poke 0xc856 8;poke 0xc857 0;poke 0xc823 0;poke 0xc804 0;poke 0xc80a 0
 poke 0xc8d4 1;poke 0xc871 5;poke 0xc891 5;poke 0xc8d0 1;poke 0xc8c1 5;poke 0xc8ad 8;poke 0xc8da 1
}
proc ready {} {
 if {[debug read "Sunrise GFX9000 regs" 8]!=0xc2 || [peek 0xc856]!=8} {after frame ready;return}
 setup 45
 after time 2 {sample left;setup 170}
 after time 4 {sample right;exit}
}
after time 10 {poke 0xc856 8;after frame ready}
after time 40 {exit 1}
