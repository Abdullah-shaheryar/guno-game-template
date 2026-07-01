extends Area2D
## A floating health pickup. Heals the player on touch, then pops with a burst.

@export var heal := 30.0

var _t := 0.0
var _base_y := 0.0

@onready var _audio: Node = get_node_or_null("/root/Audio")
@onready var _juice: Node = get_node_or_null("/root/Juice")

func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body)

func _on_body(b: Node) -> void:
	if b.is_in_group("player") and "hp" in b and "max_hp" in b:
		b.hp = minf(b.max_hp, b.hp + heal)
		if _audio != null:
			_audio.play("levelup", -8.0)
		if _juice != null:
			_juice.burst(global_position, Color(0.4, 1.0, 0.5), 16, 1.0)
		queue_free()

func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 2.5) * 6.0
