extends Label
## HUD: gun status + player HP, an on-beat gold pulse (Music-Based Combat), and a
## transient "EVOLVED" banner when a mode levels up (Living Weapon). Finds systems
## via groups / autoloads so it holds no hard references.

var _banner := ""
var _banner_t := 0.0
var _connected := false
var _gun: Node = null
var _gs: Node = null
var _bc: Node = null

func _process(delta: float) -> void:
	# Toggle the whole HUD with [H] — but never while paused (a menu is up), so it
	# can't be hidden behind a pause screen and reappear missing on resume.
	if Input.is_action_just_pressed("toggle_hud") and not get_tree().paused:
		var hud := get_parent()
		if hud != null:
			for ch in hud.get_children():
				if ch is CanvasItem:
					ch.visible = not ch.visible

	if not _connected:
		var wp := get_node_or_null("/root/WeaponProgress")
		if wp != null:
			wp.leveled_up.connect(_on_level)
			_connected = true
	if _gs == null:
		_gs = get_node_or_null("/root/GameStats")
	if _bc == null:
		_bc = get_node_or_null("/root/BeatClock")

	var txt := "GUNO"
	if _gun == null or not is_instance_valid(_gun):
		var guns := get_tree().get_nodes_in_group("gun")
		_gun = guns[0] if not guns.is_empty() else null
	if _gun != null and _gun.has_method("status_text"):
		txt = _gun.status_text()

	if _gs != null:
		txt += "\n♥ %d      ✦ %d shards      [Esc] pause      [H] hide" % [_gs.lives, _gs.shards]

	if _banner_t > 0.0:
		_banner_t -= delta
		txt += "\n" + _banner

	if txt != text:
		text = txt

	# On-beat gold flash.
	if _bc != null and _bc.on_beat():
		modulate = Color(1.0, 0.88, 0.3)
	else:
		modulate = Color(1.0, 1.0, 1.0)

func _on_level(mode_key: String, lvl: int) -> void:
	_banner = "⚡ %s EVOLVED → Lv%d!" % [mode_key, lvl]
	_banner_t = 3.0
	var a := get_node_or_null("/root/Audio")
	if a != null:
		a.play("levelup", -2.0)
