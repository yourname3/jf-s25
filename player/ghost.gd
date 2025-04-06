extends Sprite2D
class_name Ghost

var target_alpha: float = 1.0

func _process(delta: float) -> void:
	self_modulate.a += (target_alpha - self_modulate.a) * Global.get_lerp(0.1, delta)

	if target_alpha < 0.5:
		if self_modulate.a < 0.01:
			queue_free()
