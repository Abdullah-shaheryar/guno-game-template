extends Control
## A visual health bar. Reads the player's hp each frame; the fill shrinks and
## shifts green -> red as health drops.

const FULL_W := 220.0

@onready var fill: ColorRect = $Fill
@onready var label: Label = $Label

var _player: Node = null
var _last_hp: float = -1.0

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		_player = players[0] if not players.is_empty() else null
	if _player == null or fill == null:
		return
	var p = _player
	if not ("hp" in p and "max_hp" in p) or p.max_hp <= 0.0:
		return
	var ratio: float = clampf(p.hp / p.max_hp, 0.0, 1.0)
	fill.size.x = FULL_W * ratio
	fill.color = Color(0.9, 0.25, 0.25).lerp(Color(0.35, 0.9, 0.45), ratio)
	if label != null and int(p.hp) != int(_last_hp):
		label.text = "HP %d" % int(p.hp)
		_last_hp = p.hp
