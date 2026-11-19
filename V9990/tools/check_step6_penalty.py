#!/usr/bin/env python3
"""A mistaken instructor shot locks aim until the current wave expires."""
from pathlib import Path
import sys
p=Path(sys.argv[1]); elapsed=int(sys.argv[2])
a=list(map(int,(p/'result.txt').read_text().split()))
(stage,miss,miss_hits,blocked,locked,x,y,hits,mask,released,duration,seed,
 initial_time,final_time,after,before_move,after_move,hz)=a
assert (stage,miss,miss_hits,blocked,locked,x,y,hits,mask,released)==(17,0,0,1,1,64,50,0,31,1),a
assert seed!=93 and final_time<initial_time and after==0 and after_move>before_move,a
# Hit occurs about a quarter second after the original wave was timestamped;
# Step 6 groups last 2.3 s, as the arcade boards.
expected=(23-10*elapsed)*hz//10
assert expected-hz//2 <= duration <= expected+hz//4,(a,expected)
print(f'OK: instructor hit after {elapsed}s locks aim for {duration}/{hz}s until next group; clock keeps running')
