extends "res://scripts/gun/gun_mode.gd"
## Clone mode: fire to record your movement for a few seconds, then a ghost
## spawns and replays the path — holding plates, clearing enemies, then freezing
## on the final pose.

const GHOST := preload("res://scenes/clone/ghost.tscn")
const RECORD_TIME := 4.0
## A single-frame position jump larger than this means the player respawned or
## warped (their run speed tops out ~260 px/s, so a normal frame moves << this).
## Detecting it lets us abandon the recording before the ghost path is corrupted.
const TELEPORT_THRESHOLD := 250.0

var _recording: bool = false
var _t: float = 0.0
var _path: PackedVector2Array = PackedVector2Array()
var _player: Node2D = null
var _active_clone: Node = null

func _on_enter() -> void:
	if _player == null:
		_player = gun.get_parent()

func fire(_aim: Vector2, _muzzle_pos: Vector2) -> void:
	if _player == null:
		_player = gun.get_parent()
	if not _recording:
		_recording = true
		var wp := get_node_or_null("/root/WeaponProgress")
		var lv: int = wp.level("Clone") if wp != null else 0
		_t = RECORD_TIME + lv * 1.5
		_path = PackedVector2Array()

func tick(delta: float) -> void:
	if not _recording:
		return
	if _player != null:
		var pos: Vector2 = _player.global_position
		if _path.size() > 0 and pos.distance_to(_path[_path.size() - 1]) > TELEPORT_THRESHOLD:
			_recording = false
			return
		_path.append(pos)
	_t -= delta
	if _t <= 0.0:
		_recording = false
		_spawn_ghost()

## Public: drop any in-progress recording and existing ghost (called on warp).
func cancel_recording() -> void:
	_recording = false
	_path = PackedVector2Array()
	_clear_clone()

func _clear_clone() -> void:
	if _active_clone != null and is_instance_valid(_active_clone):
		_active_clone.queue_free()
	_active_clone = null

func _spawn_ghost() -> void:
	if _path.size() < 2:
		return
	# Only one clone at a time — clear the tracked ghost instead of scanning the group.
	_clear_clone()
	var g: Node = spawn_into_world(GHOST, _path[0])
	if g != null:
		_active_clone = g
		g.play(_path)

func mode_label() -> String:
	if _recording:
		return "Clone (REC %0.1fs)" % _t
	return "Clone (fire = record path)"

func mode_key() -> String:
	return "Clone"

func tip_color() -> Color:
	return Color(0.5, 0.95, 1.0)

func gun_color() -> Color:
	return Color(0.36, 0.56, 0.64)
