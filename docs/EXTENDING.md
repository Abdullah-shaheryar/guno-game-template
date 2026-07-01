# Extending GUNO — copy-paste recipes

Concrete, working skeletons for the common "add a new …" tasks. Each follows the conventions in
[../GUIDE.md](../GUIDE.md); copy, rename, fill in. After any addition, verify **0 errors / 0
warnings** in the engine (see GUIDE.md → *Verifying a change*).

> Rule of thumb: **add a new file next to an existing sibling** rather than editing a shared one.
> The fastest correct path is usually to duplicate the nearest example and change its guts.

---

## Add a gun mode

`scripts/gun/modes/dash_mode.gd`:

```gdscript
extends "res://scripts/gun/gun_mode.gd"   # by PATH — no class_name

func fire(aim: Vector2, _muzzle_pos: Vector2) -> void:
	# gun is set by Gun._ready(); gun.get_parent() is the player
	var p := gun.get_parent()
	if p != null:
		p.velocity += aim * 700.0

func secondary() -> void:
	pass

func mode_label() -> String:
	return "Dash"

func mode_key() -> String:      # UNIQUE + stable — this is the WeaponProgress key
	return "Dash"
```

Then in `scenes/player/player.tscn`, add a child `Node` under `Gun` with that script. The Gun
auto-detects it (`fire()` + `activate()`). Read level with
`get_node_or_null("/root/WeaponProgress").level("Dash")` if you want it to grow with use.

---

## Add an enemy

`scenes/enemies/charger.gd` (copy `walker.gd` for the full gravity/patrol body):

```gdscript
extends CharacterBody2D

@export var max_hp: float = 30.0
var hp: float
var _flash := 0.0
@onready var visual: Node2D = $Visual
@onready var _juice: Node = get_node_or_null("/root/Juice")
@onready var _audio: Node = get_node_or_null("/root/Audio")

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	var touch := get_node_or_null("Touch")
	if touch != null:
		touch.body_entered.connect(func(b):
			if b.is_in_group("player") and b.has_method("take_damage"): b.take_damage(8.0))

func apply_element(element: String, bullet: Node) -> void:
	var dmg := 12.0
	if bullet != null and "damage" in bullet: dmg = bullet.damage
	_take_damage(dmg)
	# match element: "fire"/"ice"/"electric" → status effects

func apply_time(direction: int, _bolt: Node) -> void:
	if direction > 0: _take_damage(20.0)   # forward = hurt

func _take_damage(amount: float) -> void:
	hp -= amount
	_flash = 0.09
	if _juice != null: _juice.shake(0.1)
	if _audio != null: _audio.play("hit", -9.0)
	if hp <= 0.0: _die()

func _die() -> void:
	if _juice != null: _juice.burst(global_position, Color(1,0.6,0.2), 20, 1.2)
	queue_free()
```

Scene: `CharacterBody2D` (**layer 1 / mask 1**) + `Visual` + `CollisionShape2D` + a `Touch`
`Area2D` (**layer 0 / mask 2**). Place instances in a zone scene.

---

## Add an interactable (reacts to the gun)

`scenes/world/crystal.gd`:

```gdscript
extends StaticBody2D          # layer 1 / mask 0

@export var hits_to_break: int = 3
var _hits := 0

func apply_element(element: String, _bullet: Node) -> void:
	if element != "electric": return          # only electric affects it
	_hits += 1
	modulate = modulate.darkened(0.2)
	if _hits >= hits_to_break:
		queue_free()
```

For a **time-reactive** object, implement `apply_time(direction: int, _bolt: Node)` instead and
toggle both visibility **and** `CollisionShape2D.disabled` (see `temporal_bridge.gd`).

Scene: `StaticBody2D` (**layer 1 / mask 0**) or `Area2D` (**layer 0 / mask 2** to sense the player)
+ `Polygon2D` visual + `CollisionShape2D`. Expose tuning as `@export`.

---

## Add a zone

1. `scenes/zones/zone5.tscn`, `Node2D` root. Entry + exit floors as `StaticBody2D`
   (**layer 1 / mask 0**) at world `y=660`, each with `Polygon2D` + `CollisionShape2D`. Keep every gap
   ≤ ~180px and every wall ≤ ~130px, or add stepping platforms / a mode-gated crossing.
2. Add enemies/props as instanced children. Add an `ExitFlag` `Polygon2D` (no collision).
3. Instance `zone5.tscn` into `scenes/main.tscn`.
4. In `scenes/zones/hub.tscn`, add a `Portal` instance:
   `target = Vector2(<entry_x>, 400)`, `label = "MY ZONE"`, `tint = Color(r,g,b,0.7)`.
5. (Optional) add a warp point in `scripts/managers/debug_warp.gd`.

Coordinates are **absolute world-space** — zones instance at origin.

---

## Add an autoload (global service)

1. `scripts/managers/save.gd` (`extends Node`, `##` doc-comment, `_private` state, small public API).
2. Register in `project.godot`:
   ```
   [autoload]
   Save="*res://scripts/managers/save.gd"
   ```
3. Use it: `var s := get_node_or_null("/root/Save")` then null-check. Emit signals for state changes.

---

## Add a collectible / pickup

Copy `scenes/world/shard.gd` (score) or `pickup.gd` (heal):

```gdscript
extends Area2D                # layer 0 / mask 2

func _ready() -> void:
	body_entered.connect(func(b):
		if b.is_in_group("player"):
			get_node_or_null("/root/GameStats").add_shard(1)
			queue_free())
```

---

## Add a UI screen

New scene + `CanvasLayer` script in `scenes/ui/` + `scripts/ui/`. Style with `menu_theme.tres`.
Trigger it from gameplay via its group (like `win_screen`/`game_over`), drive navigation with
`Transitions.change_scene()` / `get_tree().paused`. Set `pivot_offset` before any button scale tween.

---

## Checklist before you call it done

- [ ] New solids on **layer 1**, player-sensing areas on **mask 2**, bullets on **layer 0 / mask 1**.
- [ ] Registered in the right **group** if other systems need to find it.
- [ ] Autoloads fetched with `get_node_or_null` + **null-check**.
- [ ] `##` doc-comment at the top; tabs; `snake_case`; `_private` members.
- [ ] Engine diagnostics: **0 errors, 0 warnings**; playtested if it affects gameplay.
