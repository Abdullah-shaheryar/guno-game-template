extends "res://scripts/gun/gun_mode.gd"
## Gravity mode: aim + fire to rotate global gravity toward the nearest cardinal
## direction of your aim. Walk on walls/ceilings; ungrounded enemies fall away.

var _gm: Node = null

func _on_enter() -> void:
	_gm = gun.get_tree().root.get_node_or_null("GravityManager")

func fire(aim: Vector2, _muzzle_pos: Vector2) -> void:
	if _gm != null:
		_gm.set_down(aim)

func mode_label() -> String:
	return "Gravity (aim + fire = down)"

func mode_key() -> String:
	return "Gravity"

func tip_color() -> Color:
	return Color(0.72, 0.42, 1.0)

func gun_color() -> Color:
	return Color(0.44, 0.3, 0.62)
