extends Control
## Four chips that show the gun's modes; the active one (gun.current) lights up.

const BASE := [Color(1, 0.55, 0.2), Color(0.7, 0.4, 1), Color(0.45, 0.85, 0.9), Color(0.45, 0.95, 1)]

var _gun: Node = null

func _process(_delta: float) -> void:
	if _gun == null or not is_instance_valid(_gun):
		var guns := get_tree().get_nodes_in_group("gun")
		_gun = guns[0] if not guns.is_empty() else null
	if _gun == null:
		return
	var cur := 0
	var g = _gun
	if "current" in g:
		cur = g.current
	for i in 4:
		var chip := get_node_or_null("Chip%d" % i) as ColorRect
		if chip == null:
			continue
		chip.color = BASE[i] if i == cur else BASE[i].darkened(0.4)
