extends StaticBody2D
## A breakable ice wall. It physically blocks the player; FIRE chips it away and
## it shatters only after several hits, so it reads as a real obstacle (not a
## one-shot melt). Other elements just flash off it.

@export var hits_to_melt: int = 3

var _hits: int = 0

@onready var visual: Polygon2D = $Visual

func apply_element(element: String, _bullet: Node) -> void:
	if element == "fire":
		_hits += 1
		if visual != null:
			visual.color = visual.color.darkened(0.16)
			visual.scale *= 0.9
		var a := get_node_or_null("/root/Audio")
		if a != null:
			a.play("hit", -11.0)
		if _hits >= hits_to_melt:
			queue_free()
	elif visual != null:
		visual.modulate = Color(1.3, 1.3, 1.5)
