extends CharacterBody2D
## A floating enemy: hovers, drifts toward the player, contact-damages, and
## reacts to every element (same vocabulary as the walker). Gravity-aware, so a
## Gravity flip re-orients its hover/pursuit instead of leaving it stuck. Juicy hits.

@export var max_hp: float = 18.0
@export var speed: float = 78.0

const BURN_DPS := 8.0
const HOVER_DIST := 90.0   # how far "above" (opposite gravity) the player it hovers

var hp: float
var _flash := 0.0
var burn_time := 0.0
var freeze_time := 0.0
var stun_time := 0.0
var _bob := 0.0
var _origin: Vector2
var _vbase := Vector2.ONE
var _player: Node2D = null

@onready var visual: Node2D = $Visual
@onready var gm: Node = get_node_or_null("/root/GravityManager")
@onready var _juice: Node = get_node_or_null("/root/Juice")
@onready var _audio: Node = get_node_or_null("/root/Audio")

func _ready() -> void:
	hp = max_hp
	_origin = global_position
	add_to_group("enemy")
	if visual != null:
		_vbase = visual.scale
	var t := get_node_or_null("Touch")
	if t != null:
		t.body_entered.connect(_on_touch)

func _down() -> Vector2:
	if gm != null:
		return gm.down
	return Vector2.DOWN

func _get_player() -> Node2D:
	if _player == null or not is_instance_valid(_player):
		var ps := get_tree().get_nodes_in_group("player")
		_player = ps[0] if not ps.is_empty() else null
	return _player

func _on_touch(b: Node) -> void:
	if b.is_in_group("player") and b.has_method("take_damage"):
		b.take_damage(7.0)

func apply_element(element: String, bullet: Node) -> void:
	var dmg: float = 12.0
	if bullet != null and "damage" in bullet:
		dmg = bullet.damage
	_take_damage(dmg)
	match element:
		"fire":
			burn_time = 3.0
		"ice":
			freeze_time = 2.5
		"electric":
			stun_time = 1.6

func apply_time(direction: int, _bolt: Node) -> void:
	if direction > 0:
		_take_damage(18.0)
	else:
		global_position = _origin
		stun_time = 1.2

func _take_damage(amount: float) -> void:
	hp -= amount
	_flash = 0.09
	if _juice != null:
		_juice.shake(0.08)
	if _audio != null:
		_audio.play("hit", -9.0)
	if hp <= 0.0:
		_die()

func _die() -> void:
	if _juice != null:
		_juice.burst(global_position, Color(0.6, 0.45, 0.85), 20, 1.2)
		_juice.shake(0.18)
		_juice.hitstop(0.04)
	queue_free()

func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	if burn_time > 0.0:
		burn_time -= delta
		hp -= BURN_DPS * delta
		if hp <= 0.0:
			_die()
			return
	freeze_time = maxf(0.0, freeze_time - delta)
	stun_time = maxf(0.0, stun_time - delta)
	_bob += delta

	var disabled := freeze_time > 0.0 or stun_time > 0.0
	if disabled:
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	else:
		var d := _down()
		var right := d.rotated(-PI / 2.0)
		var player := _get_player()
		var target := player.global_position if player != null else _origin
		# Hover HOVER_DIST opposite gravity from the player, chasing horizontally.
		var to_hover := (target - d * HOVER_DIST) - global_position
		var along := to_hover.dot(right)
		var vert := to_hover.dot(d)
		var desired := right * (signf(along) * speed * minf(1.0, absf(along) / 60.0))
		desired += d * (clampf(vert, -60.0, 60.0) + sin(_bob * 2.5) * 28.0)
		velocity = velocity.move_toward(desired, 700.0 * delta)
	move_and_slide()

	# Wing flap.
	if visual != null:
		var f := sin(_bob * 22.0)
		visual.scale = Vector2(_vbase.x * (1.0 + f * 0.14), _vbase.y * (1.0 - f * 0.05))

	_update_color()

func _update_color() -> void:
	if visual == null:
		return
	if _flash > 0.0:
		visual.modulate = Color(5, 5, 5)
	elif freeze_time > 0.0:
		visual.modulate = Color(0.5, 0.85, 1.0)
	elif stun_time > 0.0:
		visual.modulate = Color(1.0, 0.95, 0.4)
	elif burn_time > 0.0:
		visual.modulate = Color(1.0, 0.6, 0.4)
	else:
		visual.modulate = Color(1.0, 1.0, 1.0)
