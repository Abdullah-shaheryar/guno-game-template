extends Node2D
## The weapon. Holds an ordered list of mode children, points at the mouse, and
## routes input to the active mode. Cycle modes with Q/E, fire with LMB/J, and
## trigger the active mode's secondary action with R. Modes are detected by duck
## typing (they implement fire/activate) so there's no global-class dependency.

@export var bullet_scene: PackedScene

var modes: Array = []
var current: int = 0

@onready var muzzle: Marker2D = $Muzzle
# Autoloads resolved once (they never change) instead of per-shot path lookups.
@onready var _audio: Node = get_node_or_null("/root/Audio")
@onready var _wp: Node = get_node_or_null("/root/WeaponProgress")
@onready var _juice: Node = get_node_or_null("/root/Juice")
@onready var _beat: Node = get_node_or_null("/root/BeatClock")

func _ready() -> void:
	add_to_group("gun")
	for c in get_children():
		if c.has_method("fire") and c.has_method("activate"):
			c.gun = self
			modes.append(c)
			c.deactivate()
	if not modes.is_empty():
		modes[current].activate()

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	# Keep the gun upright when aiming left. Flip only the visual (Polygon2D)
	# parts, leaving the Muzzle marker and mode nodes un-mirrored so aim_dir()
	# and muzzle.global_position stay correct in every orientation.
	var flip := -1.0 if get_global_mouse_position().x < global_position.x else 1.0
	for c in get_children():
		if c is Polygon2D:
			c.scale.y = flip

	if Input.is_action_just_pressed("cycle_mode_next"):
		_switch(1)
	elif Input.is_action_just_pressed("cycle_mode_prev"):
		_switch(-1)

	var m = _active()
	if m == null:
		return
	if Input.is_action_just_pressed("fire"):
		m.fire(aim_dir(), muzzle.global_position)
		if _audio != null:
			_audio.play("shoot", -6.0)
		if _wp != null and m.has_method("mode_key"):
			_wp.register_use(m.mode_key())
		if _juice != null:
			_juice.burst(muzzle.global_position, Color(1, 1, 0.7), 5, 0.5)
			_juice.punch(-aim_dir(), 6.0)
			if _beat != null and _beat.on_beat():
				_juice.shake(0.12)
				if _audio != null:
					_audio.play("shoot", -4.0)
	if Input.is_action_just_pressed("mode_action") and m.has_method("secondary"):
		m.secondary()
	if m.has_method("tick"):
		m.tick(delta)

func _switch(step: int) -> void:
	if modes.size() <= 1:
		return
	_active().deactivate()
	current = wrapi(current + step, 0, modes.size())
	_active().activate()
	if _juice != null:
		_juice.shake(0.08)
		_juice.burst(muzzle.global_position, Color(1, 1, 1), 4, 0.3)
	if _audio != null:
		_audio.play("levelup", -15.0)

func _active():
	if modes.is_empty():
		return null
	return modes[current]

func aim_dir() -> Vector2:
	return (get_global_mouse_position() - muzzle.global_position).normalized()

## Abandon any in-progress clone recording (e.g. the player warped through a
## portal). Safe to call whatever mode is active.
func cancel_clone() -> void:
	for m in modes:
		if m.has_method("cancel_recording"):
			m.cancel_recording()

## Text for the HUD: active mode + controls.
func status_text() -> String:
	var m = _active()
	var label = m.mode_label() if m != null else "—"
	var lvl_txt := ""
	if _wp != null and m != null and m.has_method("mode_key"):
		lvl_txt = "  Lv%d" % _wp.level(m.mode_key())
	return "MODE %d/%d  [Q/E]: %s%s\nFire: LMB/J   Secondary: R   (fire ON-BEAT = power shot)" % [current + 1, modes.size(), label, lvl_txt]
