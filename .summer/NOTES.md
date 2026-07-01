# Project Notes

**Start with [`/GUIDE.md`](../GUIDE.md)** — the full map of this template (architecture,
conventions, compartment guides, and how to verify changes). This file is just the short version.

## The 60-second version

GUNO = *one gun, four modes* (Elemental / Gravity / Time / Clone), a Godot 4 / Summer Engine
platformer. Boot: `scenes/ui/main_menu.tscn` → `scenes/main.tscn`.

Everything talks through **three channels only**:
1. **Autoloads** at `/root/Name` (fetch with `get_node_or_null` + null-check).
2. **Groups** (`player`, `enemy`, `boss`, `clone`, `gun`, …).
3. **Duck-typed methods** (`apply_element`, `apply_time`, `take_damage`, gun-mode hooks).

## Golden rules (don't break)

- **Collision:** layer 1 = world + enemies, layer 2 = player, projectiles = layer 0 / mask 1.
- **Gun modes** `extends "res://scripts/gun/gun_mode.gd"` by path, **no `class_name`**; need `fire()`+`activate()`.
- **`GameStats.reset()`** is menu/retry only (stats persist across reload).
- **`GravityManager.down`** is always cardinal; actors set `up_direction = -down`.
- **Boss shield** only drops on `apply_element("electric")` — don't bypass.
- Prefer **adding a file next to a sibling** over editing shared code. Keep it running at **0 errors / 0 warnings**.

## Where things live

`scripts/managers/` autoloads · `scripts/gun/` weapon+modes · `scenes/player/` controller ·
`scenes/enemies/` hostiles · `scenes/world/` interactables · `scripts/ui/` HUD+menus ·
`scenes/zones/` levels. **Each folder has a `README.md` guide.** Recipes: `docs/EXTENDING.md`.
Data-flow: `docs/ARCHITECTURE.md`.
