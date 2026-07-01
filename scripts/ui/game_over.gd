extends CanvasLayer
## Game-over panel. Shown when the player runs out of lives (player calls
## show_over via the "game_over" group). Retry resets stats + reloads; Main Menu exits.

func _ready() -> void:
	add_to_group("game_over")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Panel/VBox/Retry.pressed.connect(_retry)
	$Panel/VBox/MainMenu.pressed.connect(_menu)
	for b in [$Panel/VBox/Retry, $Panel/VBox/MainMenu]:
		_wire(b)

func show_over() -> void:
	var gs := get_node_or_null("/root/GameStats")
	if gs != null:
		$Panel/VBox/Sub.text = "You gathered %d shards." % gs.shards
	visible = true
	get_tree().paused = true
	$Panel/VBox/Retry.grab_focus()

func _retry() -> void:
	var gs := get_node_or_null("/root/GameStats")
	if gs != null:
		gs.reset()
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
