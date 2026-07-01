extends Node
## Debug warp (autoload). Press number keys 1-4 to teleport the player to the
## start of each zone for isolated testing. Resets gravity on warp. This is a
## testing aid for the vertical slice; it becomes the real hub in M5.

const SPOTS := {
	KEY_1: Vector2(200, 400),    # Zone 1 - Elemental
	KEY_2: Vector2(3300, 400),   # Zone 2 - Gravity
	KEY_3: Vector2(5300, 400),   # Zone 3 - Time
	KEY_4: Vector2(7150, 400),   # Zone 4 - Clone
}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if SPOTS.has(event.keycode):
			_warp(SPOTS[event.keycode])

func _warp(pos: Vector2) -> void:
	var gm := get_node_or_null("/root/GravityManager")
	if gm != null:
		gm.reset()
	for p in get_tree().get_nodes_in_group("player"):
		p.global_position = pos
		p.velocity = Vector2.ZERO
		if "_last_safe" in p:
			p._last_safe = pos
