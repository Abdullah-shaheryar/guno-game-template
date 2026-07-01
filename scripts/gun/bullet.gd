extends Area2D
class_name Bullet
## A projectile carrying an element. On contact it calls `apply_element` on
## whatever it hit and despawns. Color is set in setup() (after the element is
## known). Firing on the musical beat boosts damage + size (Music-Based Combat).

const COLORS := {
	"fire": Color(1.0, 0.5, 0.15),
	"ice": Color(0.45, 0.8, 1.0),
	"electric": Color(1.0, 0.95, 0.35),
}

var element: String = "fire"
var speed: float = 780.0
var direction: Vector2 = Vector2.RIGHT
var life: float = 1.6
var damage: float = 12.0

@onready var _bc: Node = get_node_or_null("/root/BeatClock")
@onready var _juice: Node = get_node_or_null("/root/Juice")

func setup(elem: String, dir: Vector2) -> void:
	element = elem
	direction = dir.normalized()
	rotation = direction.angle()
	if has_node("Visual"):
		$Visual.color = COLORS.get(element, Color.WHITE)
	if has_node("Trail"):
		$Trail.color = COLORS.get(element, Color.WHITE)

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	# Music-Based Combat: an on-beat shot hits harder and looks punchier.
	if _bc != null and _bc.on_beat():
		damage *= 1.6
		scale *= Vector2(1.5, 1.5)
		if has_node("Visual"):
			$Visual.modulate = Color(1.4, 1.4, 1.1)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_hit(node: Node) -> void:
	if node.has_method("apply_element"):
		node.apply_element(element, self)
	if _juice != null:
		_juice.burst(global_position, COLORS.get(element, Color.WHITE), 8, 0.7)
	queue_free()
