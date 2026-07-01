extends CanvasLayer
## Victory panel. Hidden until the boss dies (boss calls show_win via the
## "win_screen" group). Pauses the game; buttons offer Play Again / Main Menu.

func _ready() -> void:
	add_to_group("win_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Panel/VBox/PlayAgain.pressed.connect(_again)
	$Panel/VBox/MainMenu.pressed.connect(_menu)
	for b in [$Panel/VBox/PlayAgain, $Panel/VBox/MainMenu]:
		_wire(b)

func show_win() -> void:
	visible = true
	get_tree().paused = true
	$Panel/VBox/PlayAgain.grab_focus()

func _again() -> void:
	get_tree().paused = false
	var trans := get_node_or_null("/root/Transitions")
	if trans != null:
		trans.reload()
	else:
		get_tree().reload_current_scene()

func _menu() -> void:
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
