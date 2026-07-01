extends "res://scripts/gun/gun_mode.gd"
## Time mode: shoot an object to rewind (-1) or fast-forward (+1) it.
## Secondary toggles the direction. Starts on rewind (restores broken things).
##   rewind  -> restore broken bridges, knock enemies back to their origin
##   forward -> age saplings into climbable trees, decay enemies

const TIME_BOLT := preload("res://scenes/gun/time_bolt.tscn")

var direction: int = -1

func fire(aim: Vector2, muzzle_pos: Vector2) -> void:
	var b: Node = spawn_into_world(TIME_BOLT, muzzle_pos)
	if b != null:
		b.setup(direction, aim)

func secondary() -> void:
	direction = -direction

func mode_label() -> String:
	return "Time (%s)" % ("rewind" if direction < 0 else "forward")

func mode_key() -> String:
	return "Time"

func tip_color() -> Color:
	return Color(0.45, 0.85, 0.95)

func gun_color() -> Color:
	return Color(0.3, 0.5, 0.56)
