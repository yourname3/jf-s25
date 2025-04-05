extends Node2D
class_name LevelButton

@onready var detect_player = $detect_player
@onready var button_body = $button_body

func _physics_process(delta: float) -> void:
	var target_y := 0
	if detect_player.has_overlapping_bodies():
		target_y = 19.697
		
	button_body.position.y = move_toward(button_body.position.y, target_y, delta * 32)
