extends Area2D
## A bridge frozen in a broken state. Time-rewind restores it (solid + crossable);
## time-forward breaks it again. The root Area2D is the always-on target the
## time bolt detects, while a child StaticBody toggles whether it blocks/carries.

@onready var solid_col: CollisionShape2D = $Solid/SolidCol
@onready var intact_vis: Polygon2D = $IntactVisual
@onready var broken_vis: Polygon2D = $BrokenVisual

var intact: bool = false

func _ready() -> void:
	_refresh()

func apply_time(direction: int, _bolt: Node) -> void:
	intact = direction < 0
	_refresh()

func _refresh() -> void:
	# Deferred: apply_time runs inside the time bolt's hit callback, where a
	# direct collision toggle can be dropped mid physics-flush.
	solid_col.set_deferred("disabled", not intact)
	intact_vis.visible = intact
	broken_vis.visible = not intact
