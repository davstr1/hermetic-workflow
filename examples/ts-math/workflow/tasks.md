# Tasks

> Pre-built tasks for the ts-math example project.

- [ ] Create `src/clamp.ts` — a function `clamp(value: number, min: number, max: number): number` that constrains a number to a range. Requirements: returns `min` when `value < min`; returns `max` when `value > max`; returns `value` when it is within range; handles NaN by returning `min`; handles case where `min > max` by swapping them.
- [ ] Create `src/lerp.ts` — a function `lerp(start: number, end: number, t: number): number` that performs linear interpolation between two values. Requirements: returns `start` when `t` is 0; returns `end` when `t` is 1; returns midpoint when `t` is 0.5; clamps `t` to [0, 1] range before interpolating; handles NaN by returning `start`.
