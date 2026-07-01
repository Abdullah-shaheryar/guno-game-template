extends CharacterBody2D
## A recorded clone. Replays a path of positions one sample per frame, then
## freezes at the final pose (so it can keep holding a pressure plate). Its
## hitbox destroys enemies it passes through.

var _path: PackedVector2Array = PackedVector2Array()
var _i: int = 0

@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	add_to_group("clone")
	if hitbox != null:
		hitbox.body_entered.connect(_on_hitbox_body)

func play(path: PackedVector2Array) -> void:
	_path = path
	_i = 0
	if _path.size() > 0:
		global_position = _path[0]

func _process(_delta: float) -> void:
	if _path.is_empty():
		return
	if _i < _path.size():
		global_position = _path[_i]
		_i += 1
	# Past the end: hold the last recorded position.

func _on_hitbox_body(b: Node) -> void:
	if not b.is_in_group("enemy"):
		return
	# Route through apply_element so enemy rules apply — crucially the boss's
	# shield still gates the hit (Clone can't cheese through a raised shield),
	# and the boss dies via _die -> victory instead of a silent queue_free.
	if b.has_method("apply_element"):
		b.apply_element("clone", self)
	elif b.has_method("_take_damage"):
		b._take_damage(16.0)
	else:
		b.queue_free()
