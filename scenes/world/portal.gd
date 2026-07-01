extends Area2D
## A hub portal. While the player stands in it, pressing "interact" warps them to
## `target` (and resets gravity + heals). Walking through never auto-triggers, so
## the player can browse portals freely.

@export var target: Vector2 = Vector2.ZERO
@export var tint: Color = Color(0.6, 0.6, 0.9)
@export var label: String = ""

var _player: Node = null
var _pulse := 0.0

@onready var visual: Polygon2D = $Visual
@onready var name_label: Label = get_node_or_null("NameLabel")
@onready var prompt: Label = get_node_or_null("Prompt")

func _ready() -> void:
	if visual != null:
		visual.color = tint
	if name_label != null:
		name_label.text = label
		name_label.modulate = tint.lightened(0.4)
	if prompt != null:
		prompt.visible = false
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(b: Node) -> void:
	if b.is_in_group("player"):
		_player = b

func _on_exit(b: Node) -> void:
	if b == _player:
		_player = null

func _process(delta: float) -> void:
	if prompt != null:
		prompt.visible = _player != null
		if _player != null:
			_pulse += delta
			prompt.modulate.a = 0.5 + 0.5 * sin(_pulse * 5.0)
	if _player != null and Input.is_action_just_pressed("interact"):
		var gm := get_node_or_null("/root/GravityManager")
		if gm != null:
			gm.reset()
		_player.global_position = target
		_player.velocity = Vector2.ZERO
		var a := get_node_or_null("/root/Audio")
		if a != null:
			a.play("levelup", -10.0)
		if "_last_safe" in _player:
			_player._last_safe = target
		if "hp" in _player and "max_hp" in _player:
			_player.hp = _player.max_hp
		# Tell the gun to abandon any in-progress recording AND its tracked ghost,
		# so a warp can't leave a corrupt or orphaned clone behind.
		for g in get_tree().get_nodes_in_group("gun"):
			if g.has_method("cancel_clone"):
				g.cancel_clone()
		# Give a legible cue for any clone that gets dissolved by the warp.
		var juice := get_node_or_null("/root/Juice")
		for c in get_tree().get_nodes_in_group("clone"):
			if not is_instance_valid(c):
				continue
			if juice != null and c is Node2D:
				juice.burst(c.global_position, Color(0.55, 0.8, 1.0), 14, 1.0)
			c.queue_free()
