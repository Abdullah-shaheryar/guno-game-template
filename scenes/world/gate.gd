extends StaticBody2D
## A gate opened by a pressure plate. set_open(true) retracts it (collision off,
## hidden); set_open(false) closes it.

@onready var col: CollisionShape2D = $Col
@onready var visual: Polygon2D = $Visual

func set_open(open: bool) -> void:
	# Deferred: this is driven from the pressure plate's body_entered/exited
	# (a physics callback), where a direct collision toggle can be dropped.
	col.set_deferred("disabled", open)
	if visual != null:
		visual.visible = not open
