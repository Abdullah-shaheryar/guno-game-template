# GUNO — Design Spec

_Date: 2026-06-30 · Engine: Summer Engine 0.5.42 (Godot 2D) · Status: Approved_

## Concept

A 2D side-scrolling action-puzzle platformer. **One gun, four modes.** The same
weapon solves environmental puzzles and fights enemies. The player swaps modes on
the fly to reshape the world.

## Pillar

Every mode must be usable for **both** a puzzle and combat. If a mode only does one,
it isn't done.

## Architecture — modular mode system

- **Player** (`CharacterBody2D`): movement, jump, aim, health. Knows nothing about modes.
- **Gun**: holds an array of **Mode** components + a current index. Input cycles modes
  (`Q`/`E` / scroll); `fire` triggers the active mode. Each Mode is its own scene/script
  implementing a shared interface: `enter()`, `exit()`, `fire(aim_dir)`, `tick(delta)`.
  Modes are isolated, independently testable, and individually polishable.
- **World tagging**: objects opt into interactions via Godot groups / typed components —
  `meltable`, `freezable_water`, `powered`, `temporal`, `clone_solid`, `hazard`.
  A mode never hard-references a specific level object.
- **Autoloads / managers**:
  - `GravityManager` — global gravity direction + reorienting bodies.
  - `TimeService` — per-object state history (record/rewind/forward).
  - `CloneRecorder` — input recording + playback.

### Rejected alternatives
- Monolithic gun script with `if mode == X` — unmaintainable across 6 mechanics.
- Separate weapons instead of modes — violates the "one evolving gun" pillar.

## The four modes

1. **Elemental** — sub-key cycles Fire / Ice / Electric.
   - Fire: melts `meltable` ice, burns enemies (DoT), lights torches.
   - Ice: freezes `freezable_water` into solid platforms, freezes/slows enemies.
   - Electric: powers `powered` machines (doors, lifts), stuns enemies.
2. **Gravity** — fire a direction → global gravity rotates 90°; player reorients and
   walks walls/ceiling; ungrounded enemies fall into hazards.
3. **Time** — shoot a `temporal` object to rewind/fast-forward its state: rubble ↔ intact
   bridge, sapling ↔ climbable giant tree, incoming projectile rewinds back.
4. **Clone** — activate to record inputs for N seconds; a ghost clone replays them —
   stands on plates, shoots, holds doors.

## Level — "The Showcase"

One connected horizontal level, 4 themed zones, each gated so its puzzle requires that
mode, ending in a mini-boss that forces combining modes. A **hub** at spawn has 4 warp
pads to jump straight to any zone in isolation (real flow + a test harness in one).

## Art — 2D only, two-phase

- **Phase A — placeholders:** `Polygon2D` / `ColorRect` colored shapes. Lock the fun first, free.
- **Phase B — 2D sprites:** generate 2D sprite art (hero, enemies, bullets, tiles, FX) via
  Summer image generation and/or Blender renders. No 3D anywhere.

## Build milestones

| # | Milestone | Playable result |
|---|-----------|-----------------|
| M0 | Project skeleton: player move/jump, camera, ground, main scene set | a guy running & jumping |
| M1 | Gun framework + Elemental mode + Zone 1 | melt/freeze/power puzzles + combat |
| M2 | Gravity mode + Zone 2 | wall-walking |
| M3 | Time mode + Zone 3 | rewind/rebuild |
| M4 | Clone mode + Zone 4 | co-op-with-yourself |
| M5 | Hub + stitch zones + mini-boss + HUD | the full slice |
| M6 | Generate 2D sprite art, swap in + SFX/music | the pretty version |
| Later | #5 Living Weapon (progression) + #6 Music Combat (rhythm) | the meta layers |

## Controls (initial)

- Move: `A`/`D` or arrows · Jump: `Space` · Aim: mouse
- Fire: left mouse / `J` · Cycle mode: `Q` / `E` or scroll · Elemental sub-cycle: `R`
- Clone activate: `F`

## Definition of done (slice)

All four modes work, each demonstrated by one puzzle + one combat use, reachable both
through level flow and the hub warp pads, running without errors in Summer Engine.
