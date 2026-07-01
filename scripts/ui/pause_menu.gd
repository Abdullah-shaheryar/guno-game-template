extends CanvasLayer
## Styled resume panel. Esc toggles pause; buttons Resume / Restart / Main Menu /
## Quit. Processes while paused so the buttons stay clickable.

var _paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Panel/VBox/Resume.pressed.connect(_resume)
	$Panel/VBox/Restart.pressed.connect(_restart)
	$Panel/VBox/MainMenu.pressed.connect(_to_menu)
	$Panel/VBox/Quit.pressed.connect(func(): get_tree().quit())
	for b in [$Panel/VBox/Resume, $Panel/VBox/Restart, $Panel/VBox/MainMenu, $Panel/VBox/Quit]:
		_wire(b)

func _win_showing() -> bool:
	for w in get_tree().get_nodes_in_group("win_screen"):
		if "visible" in w and w.visible:
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if _win_showing():
		return
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	_paused = not _paused
	visible = _paused
	get_tree().paused = _paused
	if _paused:
		$Panel/VBox/Resume.grab_focus()

func _resume() -> void:
	_paused = false
	visible = false
	get_tree().paused = false

func _restart() -> void:
	get_tree().paused = false
	var trans := get_node_or_null("/root/Transitions")
	if trans != null:
		trans.reload()
	else:
		get_tree().reload_current_scene()

func _to_menu() -> void:
	get_tree().paused = false
	var trans := get_node_or_null("/root/Transitions")
	if trans != null:
		trans.change_scene("res://scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _wire(b: Button) -> void:
	b.mouse_entered.connect(func(): _pop(b, 1.06))
	b.focus_entered.connect(func(): _pop(b, 1.06))
	b.mouse_exited.connect(func(): _pop(b, 1.0))
	b.focus_exited.connect(func(): _pop(b, 1.0))

func _pop(b: Control, s: float) -> void:
	if b.pivot_offset == Vector2.ZERO:
		b.pivot_offset = b.size / 2.0
	var t := create_tween()
	t.tween_property(b, "scale", Vector2(s, s), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
