extends Marker2D
class_name YLine

@export var is_bottom: bool = true

func _ready() -> void:
	if is_bottom:
		Global.bottom_y = global_position.y
	else:
		Global.top_y = global_position.y
