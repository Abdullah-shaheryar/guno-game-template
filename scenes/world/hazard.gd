extends Area2D
## A hazard zone. Kills enemies that fall in. Optionally respawns the player.
## Its collision_mask decides who it can touch (Zone 2 uses enemies-only).

@export var kills_player: bool = false

func _ready() -> void:
	body_entered.connect(_on_body)

func _on_body(b: Node) -> void:
	if b.is_in_group("enemy"):
		b.queue_free()
	elif kills_player and b.is_in_group("player") and b.has_method("respawn"):
		b.respawn()
