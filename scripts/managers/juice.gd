extends Node
## Game-feel dispatcher (autoload): trauma-based screen shake, brief hitstop, and
## particle bursts. Call from anywhere: Juice.shake(0.4), Juice.burst(pos, color), etc.

const SHAKE_MAX_OFFSET := 16.0
const BURST := preload("res://scenes/fx/hit_burst.tscn")

var _trauma := 0.0
var _punch := Vector2.ZERO
var _cam: Camera2D = null
var _base_offset := Vector2.ZERO
var _hitstop_id := 0

func shake(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)

## A directional camera kick (e.g. gun recoil, heavy hit) that decays back.
func punch(dir: Vector2, amount: float) -> void:
	_punch = dir.normalized() * amount

func _process(delta: float) -> void:
	# Resolve the active camera only when the cache is empty/stale (skips a
	# per-frame lookup) and capture its authored offset once, so shake/recoil is
	# ADDED to the framing offset (e.g. the player camera's (0,-60)), not erasing it.
	if _cam == null or not is_instance_valid(_cam):
		_cam = get_viewport().get_camera_2d()
		if _cam == null:
			return
		_base_offset = _cam.offset
	var off := Vector2.ZERO
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * 1.8)
		var t := _trauma * _trauma
		off += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SHAKE_MAX_OFFSET * t
	_punch = _punch.move_toward(Vector2.ZERO, delta * 260.0)
	off += _punch
	_cam.offset = _base_offset + off

func hitstop(duration: float = 0.05) -> void:
	# Freeze briefly for impact. Overlapping calls extend rather than drop, and
	# only the most recent call restores time_scale (so a short stop can't cut a
	# longer one short, and a lost await can't leave the game frozen).
	_hitstop_id += 1
	var id := _hitstop_id
	Engine.time_scale = 0.0
	# ignore_time_scale = true so the timer still counts real time while frozen.
	await get_tree().create_timer(duration, true, false, true).timeout
	if id == _hitstop_id:
		Engine.time_scale = 1.0

func burst(pos: Vector2, color: Color, amount: int = 14, scl: float = 1.0) -> void:
	var scn := get_tree().current_scene
	if scn == null:
		return
	var b: Node = BURST.instantiate()
	scn.add_child(b)
	b.global_position = pos
	if b.has_method("setup"):
		b.setup(color, amount, scl)
