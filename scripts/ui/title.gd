extends Control
## Title screen. Any key / click starts the game. The prompt gently pulses.

var _t := 0.0

@onready var prompt: Label = get_node_or_null("Prompt")

func _process(delta: float) -> void:
	_t += delta
	if prompt != null:
		prompt.modulate.a = 0.45 + 0.45 * sin(_t * 3.0)

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed):
		var trans := get_node_or_null("/root/Transitions")
		if trans != null:
			trans.change_scene("res://scenes/main.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
