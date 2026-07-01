extends Node
## Base class for every gun mode. The Gun owns a list of these and forwards
## input to whichever one is active. Subclasses (Elemental / Gravity / Time /
## Clone) extend this by path and override the hooks below. Kept free of a
## global class_name so subclasses and the Gun never depend on scan order.

var gun: Node = null
var active: bool = false

func activate() -> void:
	active = true
	_on_enter()

func deactivate() -> void:
	active = false
	_on_exit()

# --- Override points ---------------------------------------------------------
func _on_enter() -> void:
	pass

func _on_exit() -> void:
	pass

## Primary fire. aim is a normalized world direction; muzzle_pos is world-space.
func fire(_aim: Vector2, _muzzle_pos: Vector2) -> void:
	pass

## Secondary action (e.g. Elemental cycles fire/ice/electric).
func secondary() -> void:
	pass

## Per-frame update while active.
func tick(_delta: float) -> void:
	pass

## Short label shown in the HUD.
func mode_label() -> String:
	return "Mode"

## Stable key used by the Living Weapon progression (one per mode).
func mode_key() -> String:
	return "Mode"

## Gun accent colors (the Gun applies these live): the glowing tip ball and the
## body tint. Override per mode so the weapon reads its mode at a glance.
func tip_color() -> Color:
	return Color(0.4, 0.9, 1.0)

func gun_color() -> Color:
	return Color(0.34, 0.36, 0.45)   # default gunmetal grey

# --- Shared helpers ----------------------------------------------------------
## Instantiate a scene into the running level at a world position.
func spawn_into_world(scene: PackedScene, pos: Vector2) -> Node:
	if gun == null or scene == null:
		return null
	var scn := gun.get_tree().current_scene
	if scn == null:
		return null
	var n: Node = scene.instantiate()
	scn.add_child(n)
	n.global_position = pos
	return n

## Spawn a Bullet (the Gun's bullet_scene) carrying an element string.
func spawn_bullet(element: String, aim: Vector2, muzzle_pos: Vector2) -> Node:
	var b: Node = spawn_into_world(gun.bullet_scene, muzzle_pos)
	if b != null:
		b.setup(element, aim)
	return b
