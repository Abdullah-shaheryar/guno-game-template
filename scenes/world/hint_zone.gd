extends Area2D
## A one-shot trigger that shows a tutorial hint when the player walks in.

@export_multiline var hint := ""

var _done := false

func _ready() -> void:
	body_entered.connect(_on_body)

func _on_body(b: Node) -> void:
	if _done or not b.is_in_group("player"):
		return
	_done = true
	for h in get_tree().get_nodes_in_group("hint_label"):
		if h.has_method("show_hint"):
			h.show_hint(hint)
