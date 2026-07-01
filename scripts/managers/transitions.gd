extends CanvasLayer
## Global fade transitions (autoload). Fades in from black on every scene load;
## change_scene()/reload() fade to black, swap, then fade back in.

var _rect: ColorRect

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 1)
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_fade(0.0, 0.45)

func change_scene(path: String) -> void:
	await _fade(1.0, 0.35)
	# A fresh scene must never inherit a paused tree (menus unpause before calling
	# us, but be defensive so the fade-in await can't stall and gameplay resumes).
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await _fade(0.0, 0.45)

func reload() -> void:
	await _fade(1.0, 0.35)
	get_tree().paused = false
	get_tree().reload_current_scene()
	await get_tree().process_frame
	await _fade(0.0, 0.45)

func _fade(target_a: float, dur: float) -> void:
	if _rect == null:
		return
	var t := create_tween()
	t.tween_property(_rect, "color:a", target_a, dur)
	await t.finished
