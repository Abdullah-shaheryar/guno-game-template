extends StaticBody2D
## A powered door. Electric opens it: it slides up and disables its collision.

@onready var col: CollisionShape2D = $Col
@onready var visual: Polygon2D = $Visual

var open: bool = false

func apply_element(element: String, _bullet: Node) -> void:
	if element == "electric" and not open:
		open = true
		if visual != null:
			visual.color = Color(0.95, 0.85, 0.35)
		var t := create_tween()
		t.tween_property(self, "position:y", position.y - 210.0, 0.4)
		t.tween_callback(_disable)

func _disable() -> void:
	col.disabled = true
