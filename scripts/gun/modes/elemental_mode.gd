extends "res://scripts/gun/gun_mode.gd"
## Fires elemental bullets. Secondary cycles fire -> ice -> electric.
## Living Weapon: higher Elemental level => bigger, harder-hitting bullets.

const ELEMENTS := ["fire", "ice", "electric"]
const TIP_COLORS := [Color(1.0, 0.5, 0.15), Color(0.45, 0.8, 1.0), Color(1.0, 0.95, 0.35)]  # fire / ice / electric
var index: int = 0
var _wp: Node = null

# Elemental keeps the default grey gun body; only the tip ball changes colour.
func tip_color() -> Color:
	return TIP_COLORS[index]

func _on_enter() -> void:
	_wp = get_node_or_null("/root/WeaponProgress")

func fire(aim: Vector2, muzzle_pos: Vector2) -> void:
	var b: Node = spawn_bullet(ELEMENTS[index], aim, muzzle_pos)
	if b != null and _wp != null:
		var lv: int = _wp.level("Elemental")
		b.damage *= (1.0 + 0.4 * lv)
		var s: float = 1.0 + 0.18 * lv
		b.scale *= Vector2(s, s)

func secondary() -> void:
	index = (index + 1) % ELEMENTS.size()

func mode_label() -> String:
	return "Elemental (%s)" % ELEMENTS[index]

func mode_key() -> String:
	return "Elemental"
