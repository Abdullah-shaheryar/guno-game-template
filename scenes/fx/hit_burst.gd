extends CPUParticles2D
## A one-shot particle burst that frees itself when done. Tint/size via setup().

func setup(c: Color, amt: int = 14, scl: float = 1.0) -> void:
	color = c
	amount = maxi(1, amt)
	scale = Vector2(scl, scl)

func _ready() -> void:
	one_shot = true
	emitting = true
	finished.connect(queue_free)
