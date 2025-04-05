@tool
extends Bone2D

@export var target: Bone2D
@export var enabled: bool = true

func _process(delta: float) -> void:
	if enabled:
		global_rotation = target.global_rotation
