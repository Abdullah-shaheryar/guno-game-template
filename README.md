# GUNO — one gun, four powers

A 2D action-puzzle platformer template for **Summer Engine / Godot 4**. The pillar:
**one weapon with four swappable modes** — Elemental, Gravity, Time, Clone — where every
mode is used for *both* puzzles and combat.

> Boot scene: `scenes/ui/main_menu.tscn` → `scenes/main.tscn` (hub + 4 zones + boss arena).

> **Extending it?** Start with **[`GUIDE.md`](GUIDE.md)** — the architecture map, conventions, and
> per-folder guides. Then **[`docs/EXTENDING.md`](docs/EXTENDING.md)** for copy-paste recipes and
> **[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)** for the runtime data flow. Every source folder
> also has its own `README.md` describing that compartment.

## Controls

| Action | Keys |
|--------|------|
| Move | `A`/`D` or `←`/`→` |
| Jump | `Space` / `W` |
| Aim | Mouse |
| Fire | `J` / Left-click |
| Cycle mode | `Q` / `E` |
| Secondary (element / rewind) | `R` |
| Enter portal | `↑` / `I` |
| Pause | `Esc` |
| Warp to zone (debug) | `1`–`4` |

Fire **on the music beat** (the gold ring pulses) for a power shot.

## Architecture

**Gun + Mode components.** `scenes/player/player.tscn` holds a `Gun` (`scripts/gun/gun.gd`)
with child mode nodes. Each mode `extends "res://scripts/gun/gun_mode.gd"` by PATH (no
`class_name`, so scan-order never matters) and overrides `fire() / secondary() / tick() /
mode_label() / mode_key()`. The Gun auto-collects any child that has `fire()`+`activate()`.

**World interaction by duck-typed method + groups.** Bullets/bolts call `apply_element(element, bullet)`
or `apply_time(direction, bolt)` on whatever they hit; anything implementing those reacts. Groups
used: `player`, `enemy`, `boss`, `clone`, `gun`, `hint_label`, `victory`, `win_screen`, `game_over`.

**Collision layers.** World/enemies/interactables = layer 1; player = layer 2; bullets mask = 1
(so bullets never hit the player). Areas that should detect the player use mask = 2.

**Autoloads** (`scripts/managers/`): `GravityManager` (global "down"), `Audio` (SFX pool + music +
`set_master_volume`), `BeatClock` (rhythm), `WeaponProgress` (mode leveling), `Juice`
(screen shake / hitstop / `punch` / particle `burst`), `GameStats` (lives/shards/deaths),
`Transitions` (scene fades), `DebugWarp` (keys 1–4).

## Extending the template

**Add a gun mode:** create `scripts/gun/modes/<x>_mode.gd` extending `gun_mode.gd`, override the
hooks, then add a child `Node` with that script under `Gun` in `player.tscn`.

**Add an enemy:** copy `scenes/enemies/walker.gd/.tscn`. Implement `apply_element` / `apply_time`,
`_take_damage`, `_die` (call `Juice.burst`/`shake`/`hitstop`), and `add_to_group("enemy")`.

**Add an interactable:** a body/Area2D that implements `apply_element(element, bullet)` (see
`ice_wall.gd`, `power_door.gd`, `water_gap.gd`, `temporal_bridge.gd`).

**Add a zone:** author `scenes/zones/zoneN.tscn` and instance it into `main.tscn`; add a portal
target in `hub.tscn` and a warp point in `debug_warp.gd`.

## Project layout

```
scenes/   player, gun, enemies, world, zones, ui, clone, fx
scripts/  gun (+ modes), managers (autoloads), ui
art/      hero.png, walker.png, boss.png, flyer.png  (self-made in Blender)
audio/    music + SFX
```

## Credits / assets

- **Sprites** (`art/`): modelled and rendered by hand in **Blender** (orthographic, transparent
  film, Freestyle outline) — original, no third-party art.
- **Background**: procedural (GradientTexture2D + Polygon2D shapes), no image file.
- **Audio**: 100% synthesized in code at runtime (`scripts/managers/audio.gd`) — original
  oscillator + envelope DSP for every SFX and a 120 BPM chiptune music loop. No sample files ship,
  so there is nothing third-party to license.

## Known limitations / backlog

No save/load or dedicated settings menu; no gamepad/rebinding; single short campaign with no
mid-zone checkpoints or scoring; sprites are procedurally animated (no frame animation); zones are
hand-assembled in `main.tscn` rather than a modular level loader.
