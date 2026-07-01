extends Area2D
## A pressure plate. Counts players/clones standing on it and drives a target
## node that has set_open(bool) (a Gate). Continuous weight required.

@export var door_path: NodePath

var _count: int = 0

@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(b: Node) -> void:
	if b.is_in_group("player") or b.is_in_group("clone"):
		_count += 1
		_update()

func _on_exit(b: Node) -> void:
	if b.is_in_group("player") or b.is_in_group("clone"):
		_count = maxi(0, _count - 1)
		_update()

func _update() -> void:
	var pressed := _count > 0
	if visual != null:
		visual.color = Color(0.3, 0.9, 0.4) if pressed else Color(0.6, 0.6, 0.3)
	var d := get_node_or_null(door_path)
	if d != null and d.has_method("set_open"):
		d.set_open(pressed)
