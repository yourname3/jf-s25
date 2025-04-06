extends AnimatableBody2D
class_name Door

@onready var from_pos = global_position
@export var to_pos: Node2D = null
@export var button: LevelButton = null

func _physics_process(delta: float) -> void:
	var target = from_pos
	if button.is_pressed():
		target = to_pos.global_position
		
	global_position = global_position.move_toward(target, 256.0 * 2.0 * delta)
	#move_and_collide(target - global_position)
