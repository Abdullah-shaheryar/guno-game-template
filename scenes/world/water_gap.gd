extends Area2D
## A water gap the player can't jump. An ice bullet freezes it into a solid
## crossing platform. The ice platform body starts disabled and hidden.

@onready var ice_col: CollisionShape2D = $IcePlatform/Col
@onready var ice_vis: Polygon2D = $IcePlatform/Visual
@onready var water_vis: Polygon2D = $WaterVisual

var frozen: bool = false

func _ready() -> void:
	ice_col.disabled = true
	ice_vis.visible = false

func apply_element(element: String, _bullet: Node) -> void:
	if element == "ice" and not frozen:
		frozen = true
		ice_col.disabled = false
		ice_vis.visible = true
		if water_vis != null:
			water_vis.modulate.a = 0.3
