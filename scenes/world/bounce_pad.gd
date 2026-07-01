extends Area2D
## A trampoline pad that launches the player away from gravity on contact.

@export var force := 950.0

@onready var _audio: Node = get_node_or_null("/root/Audio")
@onready var _juice: Node = get_node_or_null("/root/Juice")

func _ready() -> void:
	body_entered.connect(_on_body)

func _on_body(b: Node) -> void:
	if not b.is_in_group("player") or not ("velocity" in b):
		return
	var up := Vector2.UP
	if "gravity_dir" in b:
		up = -b.gravity_dir
	b.velocity = up * force
	if _juice != null:
		_juice.burst(global_position, Color(0.5, 1.0, 0.6), 16, 1.0)
	if _audio != null:
		_audio.play("jump", -3.0)
