extends CharacterBody2D
class_name Player

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	
	move_and_slide()
