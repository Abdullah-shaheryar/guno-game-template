# Managers — autoload singletons

Global services, each registered in `project.godot [autoload]`, living at `/root/<Name>`, and
surviving `reload`/`change_scene`. Nodes reach them with `get_node_or_null("/root/Name")` and a
null-check — **never** a hard reference. State is `_private`; the public surface is small.

## Files & public API

| File | Autoload | Public API |
|---|---|---|
| `gravity_manager.gd` | `GravityManager` | `set_down(dir: Vector2)`, `reset()`, `var down: Vector2`, `signal gravity_changed(down)` |
| `audio.gd` | `Audio` | `play(sfx: String, volume_db := -3.0)`, `set_master_volume(linear: float)` |
| `beat_clock.gd` | `BeatClock` | `on_beat(window := 0.15) -> bool`, `pulse(window := 0.18) -> float`, `var count`, `signal beat(count)` |
| `weapon_progress.gd` | `WeaponProgress` | `register_use(key: String)`, `level(key) -> int`, `total_level() -> int`, `signal leveled_up(key, lvl)` |
| `juice.gd` | `Juice` | `shake(amt)`, `punch(dir, amt)`, `burst(pos, color, amount:=14, scl:=1.0)`, `hitstop(dur:=0.05)` |
| `gamestats.gd` | `GameStats` | `reset()`, `add_shard(n:=1)`, `lose_life() -> bool`, `lives`/`shards`/`deaths`, `signal changed` |
| `transitions.gd` | `Transitions` | `change_scene(path)`, `reload()` — both `await`-able (fade out → swap → fade in) |
| `debug_warp.gd` | `DebugWarp` | keys `1`–`4` warp the player to each zone (testing aid) |

## How they connect

Push, don't pull: managers **emit signals** (`gravity_changed`, `beat`, `leveled_up`, `changed`)
and clients connect in `_ready()`/`_process()`. `GravityManager.down` is also polled directly by
enemies each physics frame.

## Add a manager

1. Add `scripts/managers/<name>.gd` (`extends Node`, `##` doc-comment, `_private` state).
2. Register in `project.godot`: `Name="*res://scripts/managers/<name>.gd"`.
3. Consume via `get_node_or_null("/root/Name")` + null-check. Full recipe in
   [../../docs/EXTENDING.md](../../docs/EXTENDING.md).

## Invariants & gotchas

- **`GameStats` persists across reload** — only menus/retry call `reset()`, never gameplay.
- **`Audio` tolerates missing clips** (`ResourceLoader.exists`) — SFX silently no-op, never crash.
- **`Juice.hitstop()` is overlap-safe**: it id-guards `Engine.time_scale`, so a short stop can't cut
  a longer one and a lost `await` can't freeze the game. Don't set `Engine.time_scale` elsewhere.
- **`Juice` preserves the camera's base offset** — it captures each camera's authored `offset` and
  *adds* shake/recoil on top (so the player camera's framing survives). Don't write `cam.offset` directly.
- **`Transitions` unpauses the tree** during a change so a menu-paused state can't carry into the next scene.
- **`WeaponProgress`**: `level()` returns 0 for an unregistered key; `PER_LEVEL=4`, `MAX_LEVEL=3`;
  a level only emits `leveled_up` once.
- **`GravityManager.down` snaps to the nearest cardinal** (`absf(x) >= absf(y)` wins).
