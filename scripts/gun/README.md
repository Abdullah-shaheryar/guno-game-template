# Gun — the weapon and its modes

The signature system: **one Gun, four hot-swappable modes**. The Gun points at the mouse, routes
input to the active mode, and cycles modes with `Q`/`E`. Modes are plain child nodes discovered by
duck typing — there is no registry and no `class_name`.

## Files

| File | Role |
|---|---|
| `gun.gd` | The `Gun` (`Node2D`). Aims at the mouse, auto-collects modes, routes fire/secondary/tick, draws HUD status. |
| `gun_mode.gd` | **Base class** every mode extends *by path*. Defines the lifecycle + override hooks + spawn helpers. |
| `modes/elemental_mode.gd` | Fires a `Bullet` carrying `fire`/`ice`/`electric`; secondary cycles element; scales with level. |
| `modes/gravity_mode.gd` | No projectile — calls `GravityManager.set_down(aim)` to rotate world gravity. |
| `modes/time_mode.gd` | Fires a `TimeBolt` with `direction` (+1 forward / −1 rewind); secondary toggles direction. |
| `modes/clone_mode.gd` | `tick()` records the player's path for a few seconds, then spawns a replaying `Ghost`. |
| `bullet.gd` (+ `scenes/gun/bullet.tscn`) | Element projectile; on hit calls `apply_element(element, self)` then frees. |
| `scenes/gun/time_bolt.gd` (+ `.tscn`) | Time projectile; on hit calls `apply_time(direction, self)` then frees. |

## The mode contract (`gun_mode.gd`)

Override only what you need; all hooks have safe empty defaults.

```gdscript
extends "res://scripts/gun/gun_mode.gd"   # by PATH, no class_name

func fire(aim: Vector2, muzzle_pos: Vector2) -> void   # primary (LMB/J)
func secondary() -> void                               # secondary (R)
func tick(delta: float) -> void                        # per-frame while active
func mode_label() -> String                            # HUD text
func mode_key() -> String                              # UNIQUE stable key for WeaponProgress
func _on_enter() -> void                               # on activate()
func _on_exit() -> void                                # on deactivate()
```

Helpers provided by the base: `spawn_into_world(scene, pos) -> Node` and
`spawn_bullet(element, aim, muzzle_pos) -> Node`. The Gun sets `self.gun` before calling `activate()`.

## How discovery works

`Gun._ready()` walks its children and treats any node with **both `fire()` and `activate()`** as a
mode (order = child order). `_process()` rotates to the mouse, flips only the `Polygon2D` visual
children when aiming left (so `Muzzle`/mode nodes keep a correct transform), and forwards input to
`modes[current]`.

## Add a mode

1. `scripts/gun/modes/<x>_mode.gd` extending `gun_mode.gd` by path; override the hooks; give a unique `mode_key()`.
2. Add a child `Node` with that script under `Gun` in `scenes/player/player.tscn`.
3. It auto-registers. Full recipe: [../../docs/EXTENDING.md](../../docs/EXTENDING.md).

## Invariants & gotchas

- **Extend by path, no `class_name`** on modes (scan-order safety).
- **`mode_key()` must be unique and stable** — it's the `WeaponProgress` key (not `mode_label()`).
- A **typo in `fire`/`activate` silently hides the mode** (duck typing won't match it).
- The Gun needs a `Muzzle` `Marker2D` child — `aim_dir()` and spawn points read `muzzle.global_position`.
- **Bullet / TimeBolt are layer 0, mask 1** (hit world+enemies, never the player). Boss shots differ (see enemies guide).
- On-beat power (bigger/harder shot) is opt-in per mode via `BeatClock.on_beat()`; Elemental does it, Clone doesn't.
- `clone_mode` cancels a recording if the player jumps >`TELEPORT_THRESHOLD` (250px) in one frame (warp/respawn);
  `cancel_recording()` is also called by portals via `Gun.cancel_clone()`.
