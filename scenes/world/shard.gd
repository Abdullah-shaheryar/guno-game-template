extends Area2D
## A collectible shard. Bobs and spins; the player scoops it for score + juice.

@export var value := 1

var _t := 0.0
var _base_y := 0.0

@onready var _audio: Node = get_node_or_null("/root/Audio")
@onready var _juice: Node = get_node_or_null("/root/Juice")
@onready var _gs: Node = get_node_or_null("/root/GameStats")

func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body)

func _on_body(b: Node) -> void:
	if not b.is_in_group("player"):
		return
	if _gs != null:
		_gs.add_shard(value)
	if _audio != null:
		_audio.play("levelup", -12.0)
	if _juice != null:
		_juice.burst(global_position, Color(1.0, 0.85, 0.3), 14, 0.9)
	queue_free()

func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 3.0) * 5.0
	rotation += delta * 2.2
