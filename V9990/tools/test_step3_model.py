"""Checks shared cameras, impacts and river interactions in the host model."""
from step3_model import Boat, Obstacle, Race, Runner

idle = (0, False, False)
run = (0, True, False)

race = Race(runners=[Runner(30, 200), Runner(60, 220)])
assert len(race.camera(0)) == len(race.camera(1)) == 2
race.runners[1].progress = 500
assert len(race.camera(0)) == len(race.camera(1)) == 1

race = Race(runners=[Runner(30, 198), Runner(90)], obstacles=[Obstacle('mine', 30, 200)])
race.tick([run, idle])
assert race.runners[0].stunned
race = Race(runners=[Runner(30, 198), Runner(90)], obstacles=[Obstacle('puddle', 30, 200)])
race.tick([(0, True, True), idle])
assert not race.runners[0].stunned

race = Race(runners=[Runner(40, 1000), Runner(90)], boats=[Boat(40, 1000)])
race.tick([idle, idle])
assert race.runners[0].boat == 0
race.obstacles = [Obstacle('log', 40, 1004)]
race.tick([run, idle])
assert race.runners[0].boat is None and not race.boats[0].active and race.runners[0].stunned

race = Race(runners=[Runner(40, 2198), Runner(90, 2000)])
race.tick([run, idle])
assert race.winner == 0 and race.runners[0].finished
print('OK: Step 3 reference model')
