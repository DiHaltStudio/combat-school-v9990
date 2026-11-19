# Fast-forward a controlled qualified race to make the range easy to try.
set throttle off
after time 10 {
    poke 0xc0df 8
    poke 0xc0de 0
    poke 0xc0d5 1
    poke 0xc095 0
}
proc range_at_normal_speed {} {
    if {[peek 0xc418] == 4} {
        set ::throttle on
        return
    }
    after frame range_at_normal_speed
}
after time 10.1 range_at_normal_speed
