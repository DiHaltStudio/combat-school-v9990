"""Reference model for the planned vertical race; coordinates are provisional.

This model is for exercising rules on the host. It is not used by the ROM.
"""
from dataclasses import dataclass, field


@dataclass
class Runner:
    x: int
    progress: int = 0
    jump: int = 0
    stunned: int = 0
    boat: int | None = None
    finished: bool = False


@dataclass
class Boat:
    x: int
    progress: int
    rider: int | None = None
    active: bool = True


@dataclass(frozen=True)
class Obstacle:
    kind: str
    x: int
    progress: int
    radius: int = 8


@dataclass
class Race:
    runners: list[Runner] = field(default_factory=lambda: [Runner(40), Runner(80)])
    boats: list[Boat] = field(default_factory=lambda: [Boat(40, 1000), Boat(80, 1000)])
    obstacles: list[Obstacle] = field(default_factory=list)
    water_start: int = 1000
    water_end: int = 1800
    finish: int = 2200
    remaining: int = 3600
    winner: int | None = None

    def in_water(self, runner):
        return self.water_start <= runner.progress < self.water_end

    def camera(self, owner, width=120, height=184):
        """Screen coordinates of runners within a camera following its owner."""
        anchor = self.runners[owner].progress
        visible = []
        for i, runner in enumerate(self.runners):
            x, y = runner.x, 120 + anchor - runner.progress
            if 0 <= x < width and 0 <= y < height:
                visible.append((i, x, y))
        return visible

    def release(self, i, lost=False):
        runner = self.runners[i]
        if runner.boat is not None:
            boat = self.boats[runner.boat]
            boat.rider = None
            boat.x, boat.progress = runner.x, runner.progress
            boat.active = not lost
            runner.boat = None

    def tick(self, inputs):
        """Advance one fixed update. Inputs are (horizontal, run, jump)."""
        if self.remaining <= 0 or all(r.finished for r in self.runners):
            return
        self.remaining -= 1
        for i, (runner, control) in enumerate(zip(self.runners, inputs)):
            if runner.finished:
                continue
            dx, run, jump = control
            runner.x = max(8, min(112, runner.x + max(-1, min(1, dx)) * 2))
            if runner.stunned:
                runner.stunned -= 1
                continue
            if jump and not self.in_water(runner) and not runner.jump:
                runner.jump = 16
            if runner.jump:
                runner.jump -= 1
            speed = (4 if runner.boat is not None else 1 if self.in_water(runner) else 2) if run else 0
            runner.progress = min(self.finish, runner.progress + speed)
            if runner.boat is not None:
                boat = self.boats[runner.boat]
                boat.x, boat.progress = runner.x, runner.progress
                if not self.in_water(runner):
                    self.release(i, lost=True)
            if self.in_water(runner) and runner.boat is None:
                for n, boat in enumerate(self.boats):
                    if boat.active and boat.rider is None and abs(boat.x-runner.x) <= 8 and abs(boat.progress-runner.progress) <= 8:
                        runner.boat, boat.rider = n, i
                        break
            for obstacle in self.obstacles:
                if abs(obstacle.x-runner.x) > obstacle.radius or abs(obstacle.progress-runner.progress) > obstacle.radius:
                    continue
                if obstacle.kind in ('puddle', 'mine') and not self.in_water(runner) and not runner.jump:
                    runner.stunned = 24
                elif obstacle.kind in ('log', 'rock') and self.in_water(runner):
                    self.release(i, lost=True)
                    runner.stunned = 16
            if runner.progress >= self.finish:
                runner.finished = True
                if self.winner is None:
                    self.winner = i
        a, b = self.runners
        if not a.finished and not b.finished and not a.stunned and not b.stunned and abs(a.x-b.x) <= 8 and abs(a.progress-b.progress) <= 8:
            trailing = 0 if a.progress < b.progress else 1 if b.progress < a.progress else None
            if trailing is not None:
                self.release(trailing)
                self.runners[trailing].stunned = 24
