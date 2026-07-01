extends CharacterBody2D
## GUNO player controller. Gravity-aware: reads the GravityManager singleton so
## the Gravity mode can rotate "down" and the player reorients onto walls and
## ceilings. Run + jump with coyote time and jump buffering, a checkpoint
## respawn that works in any gravity orientation, and a small health system.

@export var speed: float = 300.0
@export var acceleration: float = 2200.0
@export var jump_velocity: float = 620.0
@export var gravity: float = 1400.0
@export var fall_distance: float = 1300.0
@export var max_hp: float = 100.0

const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12
const INVULN_TIME := 0.8

var gravity_dir: Vector2 = Vector2.DOWN
var hp: float
var _last_safe: Vector2
var _coyote := 0.0
var _jump_buffer := 0.0
var _invuln := 0.0
var _facing := 1
var _vbase := Vector2.ONE
var _was_floor := false
var _anim_t := 0.0
var _vpos_base := Vector2.ZERO
var _squash := 0.0

@onready var gm: Node = get_node_or_null("/root/GravityManager")
@onready var visual: Sprite2D = $Visual
@onready var _audio: Node = get_node_or_null("/root/Audio")
@onready var _juice: Node = get_node_or_null("/root/Juice")

func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	_last_safe = global_position
	if visual != null:
		_vbase = visual.scale
		_vpos_base = visual.position
	if gm != null:
		gm.gravity_changed.connect(_on_gravity_changed)
		_apply_down(gm.down)
	else:
		_apply_down(Vector2.DOWN)

func _on_gravity_changed(new_down: Vector2) -> void:
	_apply_down(new_down)

func _apply_down(d: Vector2) -> void:
	gravity_dir = d
	up_direction = -d
	rotation = d.angle() - PI / 2.0

func take_damage(amount: float) -> void:
	if _invuln > 0.0:
		return
	hp -= amount
	_invuln = INVULN_TIME
	if _juice != null:
		_juice.shake(0.3)
		_juice.hitstop(0.03)
		_juice.burst(global_position, Color(1.0, 0.3, 0.3), 12, 1.0)
	if _audio != null:
		_audio.play("hit", -4.0)
	if hp <= 0.0:
		_on_death()

func respawn() -> void:
	global_position = _last_safe
	velocity = Vector2.ZERO
	hp = max_hp
	_invuln = INVULN_TIME
	# Clear motion state so a jump buffered pre-death doesn't fire on respawn.
	_coyote = 0.0
	_jump_buffer = 0.0

## A slip-up (fell off): reposition without healing or losing a life.
func _reposition() -> void:
	global_position = _last_safe
	velocity = Vector2.ZERO
	_coyote = 0.0
	_jump_buffer = 0.0

## Killed (HP hit 0): spend a life and respawn, or trigger game over.
func _on_death() -> void:
	if _audio != null:
		_audio.play("hit", -5.0)
	var gs := get_node_or_null("/root/GameStats")
	var alive := true
	if gs != null:
		alive = gs.lose_life()
	if alive:
		respawn()
	else:
		for g in get_tree().get_nodes_in_group("game_over"):
			if g.has_method("show_over"):
				g.show_over()

func _physics_process(delta: float) -> void:
	_invuln = maxf(0.0, _invuln - delta)
	modulate = Color(1.0, 0.5, 0.5) if _invuln > 0.0 else Color(1.0, 1.0, 1.0)

	var on_floor := is_on_floor()
	if on_floor:
		_last_safe = global_position
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(0.0, _coyote - delta)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)

	if not on_floor:
		velocity += gravity_dir * gravity * delta

	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity += -gravity_dir * jump_velocity
		_jump_buffer = 0.0
		_coyote = 0.0
		if _audio != null:
			_audio.play("jump", -5.0)

	# Horizontal movement perpendicular to gravity.
	var move_axis := Input.get_axis("move_left", "move_right")
	var right := gravity_dir.rotated(-PI / 2.0)

	# Face the aim direction (mouse) so the character looks where it shoots.
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.x > 6.0:
		_facing = 1
	elif to_mouse.x < -6.0:
		_facing = -1
	if visual != null:
		visual.flip_h = _facing < 0

	var along := velocity.dot(right)
	var new_along := move_toward(along, move_axis * speed, acceleration * delta)
	velocity += right * (new_along - along)

	move_and_slide()

	# Landing impulse.
	var nowf := is_on_floor()
	if nowf and not _was_floor and visual != null:
		_squash = 0.42
		if _audio != null:
			_audio.play("hit", -11.0)
	_was_floor = nowf

	# Procedural squash-and-stretch animation (walk bounce, air stretch,
	# land squash, idle breathe).
	if visual != null:
		_anim_t += delta
		_squash = maxf(0.0, _squash - delta * 3.5)
		var target_y := _vpos_base.y
		var sx := 1.0
		var sy := 1.0
		if not nowf:
			var vy_up := -velocity.dot(gravity_dir)
			var st := clampf(vy_up / 750.0, -0.32, 0.32)
			sy = 1.0 + st
			sx = 1.0 - st * 0.7
			visual.rotation = lerp_angle(visual.rotation, deg_to_rad(3.0) * _facing, 0.15)
		elif absf(move_axis) > 0.1:
			var b := sin(_anim_t * 15.0)
			target_y = _vpos_base.y - absf(b) * 5.0
			sy = 1.0 + b * 0.10
			sx = 1.0 - b * 0.10
			var lean := deg_to_rad(4.0) * signf(move_axis)
			var rock := sin(_anim_t * 7.5) * deg_to_rad(4.5)
			visual.rotation = lerp_angle(visual.rotation, lean + rock, 0.25)
		else:
			target_y = _vpos_base.y + sin(_anim_t * 2.5) * 1.2
			sy = 1.0 + sin(_anim_t * 2.5) * 0.02
			visual.rotation = lerp_angle(visual.rotation, 0.0, 0.15)
		sx += _squash
		sy -= _squash
		visual.position.y = lerp(visual.position.y, target_y, 0.4)
		visual.scale = Vector2(_vbase.x * sx, _vbase.y * sy)

	# Fell too far in the current down direction -> back to last safe footing
	# (a slip-up, not a death — costs no life).
	if (global_position - _last_safe).dot(gravity_dir) > fall_distance:
		_reposition()
