extends Node2D
class_name Goal

@onready var lightning := $Goal

func _process(delta: float) -> void:
	var rand_offset = Vector2.from_angle(randf_range(0, TAU)) * randf_range(0, 128.0)
	var rand_angle = randf_range(-0.2, 0.2)
	
	lightning.position += (rand_offset - lightning.position) * Global.get_lerp(0.01, delta)
	lightning.rotation += (rand_angle - lightning.rotation) * Global.get_lerp(0.01, delta)
