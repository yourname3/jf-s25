@tool
extends Bone2D

@export var target: Bone2D

func _process(delta: float) -> void:
	global_rotation = target.global_rotation
