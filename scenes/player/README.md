# Player — the controller

A gravity-aware `CharacterBody2D` with run/jump (coyote time + jump buffer), a small health/lives
system, fall-out repositioning, and procedural squash-&-stretch animation. It carries the **Gun**
as a child.

## Files

| File | Role |
|---|---|
| `player.gd` | Movement, gravity sync, damage/death/respawn, animation. |
| `player.tscn` | `CharacterBody2D` (layer 2 / mask 1) with `Visual` (Sprite2D), `Collision` (28×48), `Camera2D` (zoom 1.3, offset y −60), and `Gun` (Node2D at y −6 with the mode children). |

## Tuning (`@export`)

`speed=300`, `acceleration=2200`, `jump_velocity=620`, `gravity=1400`, `fall_distance=1300`, `max_hp=100`.
These set the **level-design budget**: ~137px climb, ~266px gap (see [zones guide](../zones/README.md)).

## Public surface

- `take_damage(amount)` — enemies/hazards call this; 0.8s invuln, `Juice` shake+burst, `hit` SFX; `hp<=0` → death.
- `respawn()` — teleport to `_last_safe`, restore HP, clear coyote/jump-buffer (so a buffered jump can't fire).
- Reacts to `GravityManager.gravity_changed` → reorients (`up_direction = -down`, `rotation` follows).
- In group `player`. `hp`, `gravity_dir`, `_last_safe` are read by UI/portals/enemies.

## Two ways to lose position

- **Death** (`hp<=0`) → `GameStats.lose_life()`; if that returns false, shows the `game_over` group. Costs a life.
- **Slip-up** (`_reposition`, fell >`fall_distance`) → back to `_last_safe`, **no life lost, no heal.**

## Invariants & gotchas

- `_last_safe` updates every `is_on_floor()` frame (and on portal warp); don't overwrite it elsewhere.
- Cache `Visual` base scale/position in `_ready()` — all squash/stretch multiplies from those.
- The Gun is a child at `(0,-6)`; gravity rotates the Player but **not** the Gun/Camera (gun flips `flip_h`
  itself, camera has `ignore_rotation`), so aim and framing stay correct in rotated gravity.
- `take_damage()` can fire multiple times per frame from overlapping hazards — the 0.8s invuln bounds it.
