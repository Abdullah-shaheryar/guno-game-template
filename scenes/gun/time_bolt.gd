extends Area2D
## A time projectile. Carries a direction: -1 rewind, +1 fast-forward. On hit it
## calls apply_time(direction, self) on whatever it strikes, then despawns.
## Color is set in setup() once the direction is known.

const FORWARD_COLOR := Color(0.8, 0.4, 1.0)
const REWIND_COLOR := Color(0.4, 0.9, 0.9)

var direction: int = -1
var speed: float = 720.0
var dir_vec: Vector2 = Vector2.RIGHT
var life: float = 1.8

func setup(d: int, aim: Vector2) -> void:
	direction = d
	dir_vec = aim.normalized()
	rotation = dir_vec.angle()
	if has_node("Visual"):
		$Visual.color = FORWARD_COLOR if direction > 0 else REWIND_COLOR

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	global_position += dir_vec * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_hit(node: Node) -> void:
	if node.has_method("apply_time"):
		node.apply_time(direction, self)
	queue_free()
