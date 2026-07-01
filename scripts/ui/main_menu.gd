extends Control
## Main menu: animated hero bob, drifting sparkles, and interactive buttons with
## hover/focus pop. Play -> game, How to Play -> controls panel, Quit -> exit.

var _t := 0.0
var _hero_y := 0.0

@onready var hero: Sprite2D = get_node_or_null("Hero")
@onready var controls: Control = get_node_or_null("ControlsPanel")

func _ready() -> void:
	if hero != null:
		_hero_y = hero.position.y
	var play: Button = $Menu/Play
	var howto: Button = $Menu/HowTo
	var quit: Button = $Menu/Quit
	play.pressed.connect(_play)
	howto.pressed.connect(_toggle_controls)
	quit.pressed.connect(func(): get_tree().quit())
	for b in [play, howto, quit]:
		_wire(b)
	if controls != null:
		controls.visible = false
		var close: Button = controls.get_node_or_null("VBox/Close")
		if close != null:
			close.pressed.connect(_toggle_controls)
			_wire(close)
	var slider := get_node_or_null("Volume/VolSlider")
	if slider != null:
		slider.value_changed.connect(_on_volume)
		_on_volume(slider.value)
	await get_tree().process_frame
	for b in [play, howto, quit]:
		b.pivot_offset = b.size / 2.0
	play.grab_focus()

func _on_volume(v: float) -> void:
	var a := get_node_or_null("/root/Audio")
	if a != null and a.has_method("set_master_volume"):
		a.set_master_volume(v)

func _play() -> void:
	var gs := get_node_or_null("/root/GameStats")
	if gs != null:
		gs.reset()
	var trans := get_node_or_null("/root/Transitions")
	if trans != null:
		trans.change_scene("res://scenes/main.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _toggle_controls() -> void:
	if controls != null:
		controls.visible = not controls.visible

func _wire(b: Button) -> void:
	b.mouse_entered.connect(func(): _pop(b, 1.07))
	b.focus_entered.connect(func(): _pop(b, 1.07))
	b.mouse_exited.connect(func(): _pop(b, 1.0))
	b.focus_exited.connect(func(): _pop(b, 1.0))

func _pop(b: Control, s: float) -> void:
	if b.pivot_offset == Vector2.ZERO:
		b.pivot_offset = b.size / 2.0
	var t := create_tween()
	t.tween_property(b, "scale", Vector2(s, s), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_t += delta
	if hero != null:
		hero.position.y = _hero_y + sin(_t * 2.0) * 12.0
		hero.rotation = sin(_t * 1.3) * 0.04
