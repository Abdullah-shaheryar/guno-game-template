extends Polygon2D
## A small dot that swells and flashes gold on the musical beat (Music-Based Combat).

var _base := Vector2.ONE

@onready var _bc: Node = get_node_or_null("/root/BeatClock")

func _ready() -> void:
	_base = scale

func _process(_delta: float) -> void:
	if _bc == null:
		return
	var p: float = _bc.pulse(0.18)
	scale = _base * (1.0 + 0.5 * p)
	modulate = Color(1.3, 1.0, 0.25) if _bc.on_beat() else Color(0.3, 0.32, 0.45)
