extends Node
## Global gravity direction (an autoload singleton). The Gravity gun mode
## rotates this; the player and enemies read it so everything falls the same way.

signal gravity_changed(down: Vector2)

var down: Vector2 = Vector2.DOWN

## Set gravity toward the nearest cardinal of `dir`.
func set_down(dir: Vector2) -> void:
	var d := _snap_cardinal(dir)
	if d == down:
		return
	down = d
	gravity_changed.emit(down)
	var a := get_node_or_null("/root/Audio")
	if a != null:
		a.play("shoot", -8.0)

func reset() -> void:
	set_down(Vector2.DOWN)

func _snap_cardinal(v: Vector2) -> Vector2:
	if v == Vector2.ZERO:
		return down
	if absf(v.x) >= absf(v.y):
		return Vector2.RIGHT if v.x >= 0.0 else Vector2.LEFT
	return Vector2.DOWN if v.y >= 0.0 else Vector2.UP
