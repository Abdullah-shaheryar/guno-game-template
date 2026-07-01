extends CharacterBody2D
## Mini-boss. Shielded until you stun it with ELECTRIC; while the shield is down
## (4s) elemental damage lands (FIRE deals double). It hovers and fires shots you
## can dodge — or REWIND with Time to reflect them back. Forces combining modes.

const BOSS_PROJ := preload("res://scenes/enemies/boss_projectile.tscn")
const FLYER := preload("res://scenes/enemies/flyer.tscn")
const GRAVITY_FLIP_CD := 1.0   # min seconds between gravity-stuns (anti-stunlock)

@export var max_hp: float = 180.0

var hp: float
var shielded: bool = true
var _shield_t: float = 0.0
var _fire_cd: float = 1.8
var _bob: float = 0.0
var _flash: float = 0.0
var _minion_cd := 7.0
var _stun := 0.0
var _gravity_flip_cd := 0.0
var _home: Vector2
var _player: Node2D = null

@onready var visual: Node2D = $Visual
@onready var shield_vis: Node2D = get_node_or_null("Shield")
@onready var _bar_fill: Node2D = get_node_or_null("HealthBar/BarFill")
@onready var _juice: Node = get_node_or_null("/root/Juice")
@onready var _audio: Node = get_node_or_null("/root/Audio")
@onready var _status: Label = get_node_or_null("Status")

func _ready() -> void:
	hp = max_hp
	_home = global_position
	add_to_group("enemy")
	add_to_group("boss")
	var hurt := get_node_or_null("Hurt")
	if hurt != null:
		hurt.body_entered.connect(_on_hurt_body)
	var gm := get_node_or_null("/root/GravityManager")
	if gm != null:
		gm.gravity_changed.connect(_on_gravity_flip)

func _on_gravity_flip(_down: Vector2) -> void:
	# Gravity destabilizes the guardian: drops its shield and briefly stuns it,
	# giving Gravity mode a real combat use. A cooldown prevents rapid flips from
	# permanently stunlocking the boss (it must get windows to fight back).
	if _gravity_flip_cd > 0.0:
		return
	_gravity_flip_cd = GRAVITY_FLIP_CD
	shielded = false
	_shield_t = 2.5
	_stun = 1.2
	if _juice != null:
		_juice.shake(0.2)

func apply_element(element: String, bullet: Node) -> void:
	if element == "electric":
		shielded = false
		_shield_t = 4.0
		if shield_vis != null:
			shield_vis.visible = false
		return
	if not shielded:
		var dmg: float = 12.0
		if bullet != null and "damage" in bullet:
			dmg = bullet.damage
		if element == "fire":
			dmg *= 2.0
		_take_damage(dmg)

func _take_damage(amount: float) -> void:
	hp -= amount
	_flash = 0.09
	if _bar_fill != null:
		_bar_fill.scale.x = clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
	if _audio != null:
		_audio.play("hit", -6.0)
	if _juice != null:
		_juice.shake(0.16)
		_juice.burst(global_position + Vector2(0, -10), Color(1.0, 0.7, 0.3), 10, 1.0)
	if hp <= 0.0:
		_die()

func _die() -> void:
	if _juice != null:
		_juice.burst(global_position, Color(0.6, 0.4, 1.0), 48, 2.2)
		_juice.shake(0.8)
		_juice.hitstop(0.12)
	if _audio != null:
		_audio.play("levelup", -2.0)
	for v in get_tree().get_nodes_in_group("victory"):
		if v is CanvasItem:
			v.visible = true
	# Tell the win screen the boss is down.
	for w in get_tree().get_nodes_in_group("win_screen"):
		if w.has_method("show_win"):
			w.show_win()
	queue_free()

func _on_hurt_body(b: Node) -> void:
	if b.is_in_group("player") and b.has_method("take_damage"):
		b.take_damage(12.0)

func _physics_process(delta: float) -> void:
	_stun = maxf(0.0, _stun - delta)
	_gravity_flip_cd = maxf(0.0, _gravity_flip_cd - delta)
	if not shielded:
		_shield_t -= delta
		if _shield_t <= 0.0:
			shielded = true

	# Phases: faster + meaner as health drops.
	var ratio := hp / maxf(max_hp, 1.0)
	_bob += delta
	var bob_speed := 3.0 if ratio <= 0.3 else 2.0
	if _stun <= 0.0:
		global_position.y = _home.y + sin(_bob * bob_speed) * 28.0

	var about_to_fire := false
	if _stun <= 0.0:
		_fire_cd -= delta
		about_to_fire = _fire_cd < 0.4 and _fire_cd > 0.0
		if _fire_cd <= 0.0:
			_fire_cd = 1.7 if ratio > 0.6 else (1.15 if ratio > 0.3 else 0.85)
			_shoot()
		# Phase 2+ (<60% hp): summon flyer minions, capped.
		if ratio <= 0.6:
			_minion_cd -= delta
			if _minion_cd <= 0.0:
				_minion_cd = 7.0
				_spawn_minion()

	_flash = maxf(0.0, _flash - delta)
	if visual != null:
		if _flash > 0.0:
			visual.modulate = Color(4, 4, 4)
		elif _stun > 0.0:
			visual.modulate = Color(1.3, 1.15, 0.4)          # stunned (gravity): yellow
		elif about_to_fire:
			visual.modulate = Color(1.7, 0.5, 0.4)            # telegraph: red wind-up
		elif shielded:
			var p := 0.5 + 0.5 * sin(_bob * 6.0)
			visual.modulate = Color(1, 1, 1).lerp(Color(0.55, 0.85, 1.4), p)  # "zap me" pulse
		else:
			visual.modulate = Color(1.0, 0.5, 0.5)            # vulnerable

	# Teach the shield mechanic right on the boss (why FIRE alone "does nothing").
	if _status != null:
		if shielded:
			_status.text = "SHIELDED - zap with ELECTRIC"
			_status.modulate = Color(0.7, 0.9, 1.4)
		else:
			_status.text = "VULNERABLE! - FIRE burns 2x"
			_status.modulate = Color(1.0, 0.6, 0.5)

func _spawn_minion() -> void:
	if get_tree().get_nodes_in_group("enemy").size() > 5:
		return
	var scn := get_tree().current_scene
	if scn == null:
		return
	var f: Node = FLYER.instantiate()
	scn.add_child(f)
	f.global_position = global_position + Vector2(randf_range(-130.0, 130.0), -70.0)

func _get_player() -> Node2D:
	if _player == null or not is_instance_valid(_player):
		var ps := get_tree().get_nodes_in_group("player")
		_player = ps[0] if not ps.is_empty() else null
	return _player

func _shoot() -> void:
	var player := _get_player()
	if player == null:
		return
	var scn := get_tree().current_scene
	if scn == null:
		return
	var dir: Vector2 = (player.global_position - global_position).normalized()
	var b: Node = BOSS_PROJ.instantiate()
	scn.add_child(b)
	b.global_position = global_position
	b.setup(dir)
