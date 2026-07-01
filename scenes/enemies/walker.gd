extends CharacterBody2D
class_name Walker
## A patrolling ground enemy. Gravity-aware; reacts to each element; juicy hits
## (white flash, screen shake, particle burst + hitstop on death).

@export var max_hp: float = 30.0
@export var speed: float = 70.0
@export var gravity: float = 1300.0
@export var patrol_range: float = 130.0

const BURN_DPS := 9.0

var hp: float
var move_dir: int = -1
var burn_time: float = 0.0
var freeze_time: float = 0.0
var stun_time: float = 0.0
var _flash: float = 0.0
var _origin: Vector2
var _vbase := Vector2.ONE
var _anim := 0.0

@onready var visual: Node2D = $Visual
@onready var gm: Node = get_node_or_null("/root/GravityManager")

func _ready() -> void:
	hp = max_hp
	_origin = global_position
	add_to_group("enemy")
	if visual != null:
		_vbase = visual.scale
	var touch := get_node_or_null("Touch")
	if touch != null:
		touch.body_entered.connect(_on_touch)

func _on_touch(b: Node) -> void:
	if b.is_in_group("player") and b.has_method("take_damage"):
		b.take_damage(8.0)

func _down() -> Vector2:
	if gm != null:
		return gm.down
	return Vector2.DOWN

func apply_element(element: String, bullet: Node) -> void:
	var dmg: float = 12.0
	if bullet != null and "damage" in bullet:
		dmg = bullet.damage
	_take_damage(dmg)
	match element:
		"fire":
			burn_time = 3.0
		"ice":
			freeze_time = 2.0
		"electric":
			stun_time = 1.5

func apply_time(direction: int, _bolt: Node) -> void:
	if direction > 0:
		_take_damage(20.0)
	else:
		global_position = _origin
		stun_time = 1.0

func _take_damage(amount: float) -> void:
	hp -= amount
	_flash = 0.09
	var j := get_node_or_null("/root/Juice")
	if j != null:
		j.shake(0.10)
	var a := get_node_or_null("/root/Audio")
	if a != null:
		a.play("hit", -9.0)
	if hp <= 0.0:
		_die()

func _die() -> void:
	var j := get_node_or_null("/root/Juice")
	if j != null:
		j.burst(global_position, Color(1.0, 0.55, 0.2), 22, 1.3)
		j.shake(0.22)
		j.hitstop(0.05)
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
	var disabled := freeze_time > 0.0 or stun_time > 0.0

	var d := _down()
	up_direction = -d
	var right := d.rotated(-PI / 2.0)
	var on_floor := is_on_floor()

	if not on_floor:
		velocity += d * gravity * delta
	else:
		velocity -= d * velocity.dot(d)

	var rv := velocity.dot(right)
	if disabled or not on_floor:
		velocity -= right * rv
	else:
		var disp := (global_position - _origin).dot(right)
		if disp > patrol_range and move_dir > 0:
			move_dir = -1
		elif disp < -patrol_range and move_dir < 0:
			move_dir = 1
		if is_on_wall():
			move_dir = -move_dir
		velocity += right * (move_dir * speed - rv)

	move_and_slide()

	# Waddle animation while patrolling.
	_anim += delta
	if visual != null:
		if not disabled and on_floor and absf(velocity.dot(right)) > 5.0:
			var b := sin(_anim * 13.0)
			visual.scale = Vector2(_vbase.x * (1.0 - b * 0.07), _vbase.y * (1.0 + b * 0.07))
			visual.rotation = b * 0.06
		else:
			visual.scale = visual.scale.lerp(_vbase, 0.2)
			visual.rotation = lerp_angle(visual.rotation, 0.0, 0.2)

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
