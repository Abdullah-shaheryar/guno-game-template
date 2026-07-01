# World — interactables & level props

The objects a level is built from. Most react to the gun (via `apply_element`/`apply_time`); the
rest react to player contact or a pressure signal. Each is a small self-contained scene + script.

## Files by how they react

**To element bullets** (`apply_element(element, bullet)`):
| File | Reacts to | Effect |
|---|---|---|
| `ice_wall.gd` | `fire` | Multi-hit melt, then shatters (blocks until destroyed). |
| `water_gap.gd` | `ice` | Freezes into a solid `IcePlatform` you can walk across. |
| `power_door.gd` | `electric` | Opens (slides + disables collision). |

**To time bolts** (`apply_time(direction, bolt)`):
| File | `-1` rewind / `+1` forward |
|---|---|
| `temporal_bridge.gd` | Toggles between broken (visual only) and intact (solid). |
| `temporal_tree.gd` | Grows / shrinks a 3-step climbable staircase. |

**To pressure & contact:**
| File | Behaviour |
|---|---|
| `pressure_plate.gd` | Counts `player`+`clone` bodies; drives its target `gate.set_open(bool)` (via `door_path`). |
| `gate.gd` | `set_open(bool)` toggles collision + visibility. |
| `portal.gd` | On `interact` warps the player to `target`, resets gravity, heals, cancels clone recording. |
| `bounce_pad.gd` | Launches the player opposite `gravity_dir` (`force`). |
| `pickup.gd` | Heals `heal` (clamped to max), frees itself. |
| `shard.gd` | Collectible; `GameStats.add_shard(value)`, frees itself. |
| `hazard.gd` | Kills enemies (and the player if `kills_player`). |
| `hint_zone.gd` | One-shot: shows `hint` text via the `hint_label` group. |
| `moving_platform.gd` | `AnimatableBody2D` oscillating `travel` over `period`; carries the player. |
| `underground.tscn` | Purely visual dark fill below ground (z −5, no collision). |

## Key exports

`Portal.target: Vector2` / `.tint: Color` / `.label: String` · `BouncePad.force` · `Pickup.heal` ·
`Shard.value` · `HintZone.hint` · `IceWall.hits_to_melt` · `PressurePlate.door_path: NodePath` ·
`Hazard.kills_player: bool` · `MovingPlatform.travel: Vector2` / `.period: float`.

## Add an interactable

Extend `StaticBody2D` (**layer 1 / mask 0**) or `Area2D` (**layer 0 / mask 2** to sense the player),
implement `apply_element` and/or `apply_time`, add a `Polygon2D` visual + `CollisionShape2D`, expose
tuning as `@export`. Full recipe: [../../docs/EXTENDING.md](../../docs/EXTENDING.md).

## Invariants & gotchas

- `apply_element` receives `bullet` as a bare `Node` — check `"damage" in bullet` before reading it.
- `apply_time` direction is an **int** (`+1`/`-1`), never 0/bool.
- **Portal warp clears ALL `clone` group members** and calls `Gun.cancel_clone()` — a mid-replay clone vanishes.
- `water_gap` ice platform starts **disabled + hidden**; only `ice` enables it.
- `temporal_tree`/`gate` toggle both **visibility AND `CollisionShape2D.disabled`** — visibility alone isn't enough.
- `moving_platform` drives `global_position` (not `position`) so a transformed parent can't distort it.
- `hint_zone` is one-shot (`_done`); it won't retrigger.
