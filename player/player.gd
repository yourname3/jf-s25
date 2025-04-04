extends CharacterBody2D
class_name Player

const H_VEL = 500.0
const H_ACCEL = 1500.0

func h_input() -> float:
	return Input.get_axis("left", "right")

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	
	var target_x_vel := h_input() * H_VEL
	var x_accel: float = sign(target_x_vel - velocity.x)
	var x_accel_integrated = x_accel * delta
	
	if abs(x_accel_integrated) > abs(target_x_vel - velocity.x):
		x_accel_integrated = target_x_vel - velocity.x
	
	velocity.x += x_accel_integrated
	
	
	move_and_slide()
