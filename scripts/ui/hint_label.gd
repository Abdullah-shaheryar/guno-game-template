extends Label
## Center-bottom tutorial hint. Other nodes call show_hint(text); it fades in,
## holds, then fades out.

var _t := 0.0

func _ready() -> void:
	add_to_group("hint_label")
	modulate.a = 0.0

func show_hint(t: String) -> void:
	text = t
	_t = 4.5

func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		modulate.a = move_toward(modulate.a, 1.0, delta * 4.0)
	else:
		modulate.a = move_toward(modulate.a, 0.0, delta * 3.0)
