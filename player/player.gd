extends CharacterBody2D
class_name Player

const H_VEL = 1024.0
const H_ACCEL = 4096.0

func h_input() -> float:
	return Input.get_axis("left", "right")

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	
	var target_x_vel := h_input() * H_VEL
	print(target_x_vel)
	var x_accel: float = sign(target_x_vel - velocity.x) * H_ACCEL
	var x_accel_integrated = x_accel * delta
	
	if abs(x_accel_integrated) > abs(target_x_vel - velocity.x):
		x_accel_integrated = target_x_vel - velocity.x
	print(x_accel_integrated)
	
	velocity.x += x_accel_integrated
	
	move_and_slide()
