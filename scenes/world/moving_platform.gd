extends AnimatableBody2D
## An oscillating platform that carries the player (AnimatableBody2D + sync_to_physics).

@export var travel: Vector2 = Vector2(180, 0)
@export var period: float = 3.0

var _base: Vector2
var _t := 0.0

func _ready() -> void:
	sync_to_physics = true
	# Drive motion in world space so a non-identity parent transform on the
	# Dynamics container can't distort the platform's travel.
	_base = global_position

func _physics_process(delta: float) -> void:
	_t += delta
	global_position = _base + travel * sin(_t * TAU / period)
