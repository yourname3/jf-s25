extends CharacterBody2D
class_name Player

const H_VEL := 256.0 * 6
const H_ACCEL := 2048.0

const JUMP_TIME := 0.4
const JUMP_SPEED := 1024.0 + 512.0

var jump_timer: float = 0.0

func h_input() -> float:
	return Input.get_axis("left", "right")

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	
	var target_x_vel := h_input() * H_VEL
	var x_accel: float = sign(target_x_vel - velocity.x) * H_ACCEL
	
	if target_x_vel == 0:
		x_accel *= 0.5
	if not is_on_floor():
		x_accel *= 0.75
	
	var x_accel_integrated = x_accel * delta
	
	if abs(x_accel_integrated) > abs(target_x_vel - velocity.x):
		x_accel_integrated = target_x_vel - velocity.x
	
	velocity.x += x_accel_integrated
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		jump_timer = JUMP_TIME
	if not Input.is_action_pressed("jump"):
		jump_timer = 0
		
	if jump_timer > 0:
		jump_timer -= delta
		velocity.y = -JUMP_SPEED
	
	# floor_max_angle = deg_to_rad(15)
	move_and_slide()
	
	if velocity.y > 0:
		# Disable jumps if we ever lose our Y velocity.
		jump_timer = 0
