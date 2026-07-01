extends StaticBody2D
## A stationary turret: aims its barrel at the player and fires periodic shots
## (which you can dodge or rewind). Ice/electric disable it briefly; all elements
## and time damage it. Self-made shapes, juicy death.

const BOSS_PROJ := preload("res://scenes/enemies/boss_projectile.tscn")

@export var max_hp: float = 40.0
@export var fire_interval: float = 2.5

var hp: float
var _cd := 1.2
var _disabled := 0.0
var _flash := 0.0
var _player: Node2D = null

@onready var body: Node2D = get_node_or_null("Body")
@onready var barrel: Node2D = get_node_or_null("Body/Barrel")
@onready var _juice: Node = get_node_or_null("/root/Juice")
@onready var _audio: Node = get_node_or_null("/root/Audio")

func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")

## The player persists for the level, so resolve it once and re-resolve only if
## the reference goes stale (avoids a group query every frame).
func _get_player() -> Node2D:
	if _player == null or not is_instance_valid(_player):
		var ps := get_tree().get_nodes_in_group("player")
		_player = ps[0] if not ps.is_empty() else null
	return _player

func apply_element(element: String, bullet: Node) -> void:
	var dmg: float = 12.0
	if bullet != null and "damage" in bullet:
		dmg = bullet.damage
	_take_damage(dmg)
	if element == "ice" or element == "electric":
		_disabled = 2.2

func apply_time(direction: int, _bolt: Node) -> void:
	if direction > 0:
		_take_damage(20.0)
	else:
		_disabled = 1.6

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
		_juice.burst(global_position, Color(0.85, 0.55, 0.3), 26, 1.4)
		_juice.shake(0.22)
		_juice.hitstop(0.05)
	queue_free()

func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_disabled = maxf(0.0, _disabled - delta)
	if body != null:
		if _flash > 0.0:
			body.modulate = Color(5, 5, 5)
		elif _disabled > 0.0:
			body.modulate = Color(0.55, 0.8, 1.0)
		else:
			body.modulate = Color(1, 1, 1)

	var player := _get_player()
	if player == null:
		return
	var aim: Vector2 = player.global_position - global_position
	if barrel != null:
		barrel.rotation = aim.angle()
	if _disabled > 0.0:
		return
	_cd -= delta
	if _cd <= 0.0:
		_cd = fire_interval
		_shoot(aim.normalized())

func _shoot(dir: Vector2) -> void:
	var scn := get_tree().current_scene
	if scn == null:
		return
	var b: Node = BOSS_PROJ.instantiate()
	scn.add_child(b)
	b.global_position = global_position + dir * 52.0
	b.setup(dir)
