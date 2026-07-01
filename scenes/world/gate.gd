extends StaticBody2D
## A gate opened by a pressure plate. set_open(true) retracts it (collision off,
## hidden); set_open(false) closes it.

@onready var col: CollisionShape2D = $Col
@onready var visual: Polygon2D = $Visual

func set_open(open: bool) -> void:
	col.disabled = open
	if visual != null:
		visual.visible = not open
