# GUNO template — start here

GUNO is a **2D action-puzzle platformer template** for **Summer Engine / Godot 4**.
The pillar: **one gun, four swappable modes** (Elemental, Gravity, Time, Clone) where every
mode is used for *both* puzzles and combat. This file is the map for understanding and safely
extending the codebase. Skim it, then open the folder guide for whatever you're touching.

> **Prime directive for edits:** the game currently runs clean (0 errors / 0 warnings) and is
> playable. Keep it that way. This is a *template* — favour small, isolated, convention-following
> changes over refactors. After any change, verify with the engine's diagnostics (see
> [Verifying a change](#verifying-a-change)).

---

## 30-second orientation

- **Boot scene:** `scenes/ui/main_menu.tscn` (set as `run/main_scene`) → Play → `scenes/main.tscn`
  (the whole world: hub + 4 zones + boss arena, assembled by hand).
- **The player** (`scenes/player/player.tscn`) carries a **Gun** (`scripts/gun/gun.gd`) whose
  child nodes are the four **modes**.
- **Everything talks through three thin channels** (no big base classes, no tight coupling):
  1. **Autoload singletons** (`/root/Name`) for global services.
  2. **Groups** (`get_tree().get_nodes_in_group("...")`) as the only global registry.
  3. **Duck-typed methods** (`if x.has_method("apply_element"): ...`) for interactions.

If you understand those three channels + the collision layers below, you understand the game.

---

## Compartment map

Each folder has its own `README.md` guide. Open the one you're working in.

| Compartment | Folder | What it owns |
|---|---|---|
| **Managers** | [`scripts/managers/`](scripts/managers/README.md) | The 8 autoload singletons (global services) |
| **Gun** | [`scripts/gun/`](scripts/gun/README.md) | The weapon, the mode base class, the 4 modes, projectiles |
| **Player** | [`scenes/player/`](scenes/player/README.md) | The controller: movement, gravity, health, animation |
| **Enemies** | [`scenes/enemies/`](scenes/enemies/README.md) | Walker, flyer, turret, boss, projectile, clone/ghost |
| **World** | [`scenes/world/`](scenes/world/README.md) | Interactables: ice/water/door, bridge/tree, plate/gate, portal, platforms, pickups |
| **UI** | [`scripts/ui/`](scripts/ui/README.md) | HUD, menus, screens, scene-flow, hints |
| **Zones** | [`scenes/zones/`](scenes/zones/README.md) | The 5 zone scenes + how the world is assembled + level-design budget |

Deeper docs: **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** (data-flow & lifecycles) ·
**[docs/EXTENDING.md](docs/EXTENDING.md)** (copy-paste recipes).

---

## The conventions (learn these once)

### 1. Collision layers & masks

Two physics layers do all the work. **Match this table for anything new**, or things will
collide wrong (bullets hitting the player, enemies falling through floors, etc.).

| Node kind | `collision_layer` | `collision_mask` | Why |
|---|---|---|---|
| World / floors / interactables (`StaticBody2D`) | **1** | 0 | solid; doesn't need to scan |
| Enemy body — walker/flyer/boss (`CharacterBody2D`) | **1** | 1 | solid to player, walks on world |
| Turret (`StaticBody2D`) | **1** | 0 | solid |
| Player (`CharacterBody2D`) | **2** | 1 | collides with world (layer 1) |
| Player bullet / time bolt (`Area2D`) | 0 | **1** | senses world+enemies, **never** the player |
| Boss projectile (`Area2D`) | **1** | **3** | hits player+world; on layer 1 so a **time bolt can reflect it** |
| Enemy `Touch`/`Hurt` area (`Area2D`) | 0 | **2** | detects the player only |
| Clone `Hitbox` (`Area2D`) | 0 | **1** | damages enemies only |
| Portal (`Area2D`) | 0 | **2** | detects the player only |

Mnemonic: **Layer 1 = world + enemies** (things bullets hit). **Layer 2 = player** (thing
enemies touch). **Projectiles live on layer 0** and are pure sensors (except the boss shot,
which sits on layer 1 so it can be rewound).

### 2. Groups (the global registry)

Register with `add_to_group("x")` in `_ready()`; find with `get_tree().get_nodes_in_group("x")`.

`player` · `enemy` · `boss` · `clone` · `gun` · `hint_label` · `victory` · `win_screen` · `game_over`

### 3. Autoload singletons

Declared in `project.godot [autoload]`, always at `/root`, survive `reload`/`change_scene`.
**Always fetch defensively:** `var j := get_node_or_null("/root/Juice")` then null-check.

| Autoload | Purpose | Most-used API |
|---|---|---|
| `GravityManager` | global "down" vector | `set_down(dir)`, `reset()`, `down`, signal `gravity_changed(down)` |
| `Audio` | SFX pool + music | `play(sfx, volume_db=-3.0)`, `set_master_volume(0..1)` |
| `BeatClock` | rhythm (120 BPM) | `on_beat(window=0.15) -> bool`, `pulse(window=0.18) -> float`, signal `beat(count)` |
| `WeaponProgress` | mode leveling (Living Weapon) | `register_use(key)`, `level(key) -> int`, signal `leveled_up(key, lvl)` |
| `Juice` | game feel | `shake(amt)`, `punch(dir, amt)`, `burst(pos, color, amount=14, scl=1)`, `hitstop(dur=0.05)` |
| `GameStats` | run stats (persist across reload) | `reset()`, `add_shard(n=1)`, `lose_life() -> bool`, `lives`/`shards`/`deaths`, signal `changed` |
| `Transitions` | fade scene changes | `change_scene(path)`, `reload()` (both `await`-able) |
| `DebugWarp` | testing: keys `1`–`4` warp to zones | — |

### 4. Duck-typed interaction interfaces

No interface types — a node "implements" an interface just by having the method. Callers guard
with `has_method(...)`.

| Method | Implemented by | Called by | Contract |
|---|---|---|---|
| `apply_element(element: String, bullet: Node)` | enemies, destructibles | `Bullet._on_hit` | `element` ∈ `fire`/`ice`/`electric`/`clone`; read `bullet.damage` only after `"damage" in bullet` |
| `apply_time(direction: int, bolt: Node)` | enemies, temporal objects, boss shot | `TimeBolt._on_hit` | `direction` = `+1` forward / `-1` rewind (never 0) |
| `take_damage(amount: float)` | **player** | enemy `Touch` areas, hazards | respects the 0.8s invuln window |
| `_take_damage(amount: float)` | enemies | their own `apply_element` | reduce hp, flash, `_die()` at `hp <= 0` |
| `set_open(open: bool)` | `gate` | `pressure_plate` | open/close via collision + visibility |

### 5. The gun-mode pattern (path-extends, no `class_name`)

Gun modes **`extends "res://scripts/gun/gun_mode.gd"` by PATH and declare no `class_name`** — this
is deliberate so mode discovery never depends on script scan order. The `Gun` auto-collects any
child node that has both `fire()` and `activate()` (duck typing). *(Note: `class_name` is fine
elsewhere in the codebase — e.g. `Walker`, `Bullet`. The path-extends rule is specific to gun
modes.)* See [`scripts/gun/README.md`](scripts/gun/README.md).

### 6. Player physics budget (for level design)

`jump_velocity=620`, `gravity=1400`, `speed=300` ⇒ **~137px max climb height, ~266px max gap.**
Design zones inside this budget; anything larger needs stepping platforms or a mode-based
crossing (freeze water, gravity-flip, time bridge). See [`scenes/zones/README.md`](scenes/zones/README.md).

---

## Golden invariants (don't break these)

- **Autoloads are global** — never make one a child of a scene; always `get_node_or_null` + null-check.
- **`GameStats.reset()` is called by menus/retry only**, never by gameplay (stats persist across reload).
- **`GravityManager.down` is always a cardinal** (UP/DOWN/LEFT/RIGHT). Actors set `up_direction = -down`.
- **Projectiles `queue_free()` after a hit** — no lingering, no double-hits.
- **A gun mode must define `fire()` + `activate()`** or the Gun won't see it; `mode_key()` must be a
  unique stable string (it's the `WeaponProgress` key).
- **The boss shield gates damage**: only `apply_element("electric")` drops it; other elements/clone
  do nothing while shielded. Don't bypass this.
- **Keep the collision table above.** New solids → layer 1; new player-sensing areas → mask 2;
  new bullets → layer 0 / mask 1.
- **Zone floors live in absolute world coordinates** (zones instance at origin). Portal `target` is a
  raw world `Vector2`.

---

## Verifying a change

This project runs inside **Summer Engine** (Godot 4), driven via the `mcp__summer-engine__*` tools.
After edits:

1. `summer_open_scene` the scene you touched (or `scenes/main.tscn`).
2. `summer_play` it, then `summer_get_diagnostics` — **require `total_errors: 0` and `total_warnings: 0`.**
3. For gameplay/visual changes, take a screenshot to confirm.
4. `summer_stop` when done.

GDScript style here: tabs for indent, `snake_case`, `_private` members underscore-prefixed, a
`##` doc-comment at the top of every script. Match the surrounding file.

---

## What NOT to touch without a reason

`.summer/GameSoul.md` is the build-log (append, don't rewrite). `art/` sprites are hand-made in
Blender (not generated — copyright). Autoload names and the collision scheme are load-bearing;
changing them ripples everywhere. When in doubt, add a new file following an existing sibling
rather than modifying a shared one.
