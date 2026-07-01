extends Area2D
## A boss shot. Damages the player. Time-rewind reflects it (turns green) so it
## flies back and damages the boss, bypassing its shield.

var dir: Vector2 = Vector2.RIGHT
var speed: float = 320.0
var life: float = 4.0
var from_boss: bool = true

func setup(d: Vector2) -> void:
	dir = d.normalized()

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	global_position += dir * speed * delta
	rotation = dir.angle()
	life -= delta
	if life <= 0.0:
		queue_free()

func apply_time(direction: int, _bolt: Node) -> void:
	if direction < 0:
		dir = -dir
		from_boss = false
		modulate = Color(0.5, 1.0, 0.6)

func _on_hit(node: Node) -> void:
	if from_boss and node.is_in_group("player") and node.has_method("take_damage"):
		node.take_damage(12.0)
		queue_free()
	elif not from_boss and node.is_in_group("enemy") and node.has_method("_take_damage"):
		# A Time-reflected shot damages ANY enemy it flies back into — the boss
		# (bypassing its shield) or a turret that fired it.
		node._take_damage(30.0)
		queue_free()
	elif from_boss and node is StaticBody2D:
		# Only the boss's own shots die on world geometry; a reflected shot must
		# be able to fly back past walls/turrets to reach the boss.
		queue_free()
