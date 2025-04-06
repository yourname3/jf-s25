extends Node2D
class_name LevelButton

@onready var detect_player = $detect_player
@onready var button_body = $button_body

const UN_Y = 0
const PRESSED_Y = 19.697

var was_pressed: bool = false

func _physics_process(delta: float) -> void:
	var target_y := 0
	if detect_player.has_overlapping_bodies():
		target_y = PRESSED_Y
		
	button_body.position.y = move_toward(button_body.position.y, target_y, delta * 32)
	
	var is_pressed = is_pressed()
	if is_pressed != was_pressed:
		Sounds.machine.play()
	was_pressed = is_pressed
	
func is_pressed() -> bool:
	var center = (UN_Y + PRESSED_Y) / 2
	return button_body.position.y > center
