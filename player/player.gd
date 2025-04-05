extends RigidBody2D
class_name Player

const H_VEL := 256.0 * 6
const H_ACCEL := 2048.0

const JUMP_TIME := 0.4
const JUMP_SPEED := 1024.0 + 512.0

var jump_timer: float = 0.0

var recording: Array[Vector2] = []
var mode: int = 0

var is_recording: bool = false

var playback_frame: int = 0

const MODE_PLAYER = 0
const MODE_PLAYBACK = 1

var original_position: Vector2

func _ready() -> void:
	original_position = global_position

func h_input() -> float:
	return Input.get_axis("left", "right")
	
## Returns the encoded inputs, either from the player itself or from the recording.
func get_inputs() -> Vector2:
	var input: Vector2 = Vector2.ZERO
	if mode == MODE_PLAYER:
		input.x = h_input()
		# Some ad-hoc enccoding for the jump inputs.
		if Input.is_action_just_pressed("jump"):
			input.y = 1
		elif Input.is_action_pressed("jump"):
			input.y = 2
	if mode == MODE_PLAYBACK:
		if playback_frame < recording.size():
			input = recording[playback_frame]
			playback_frame += 1
		else:
			#queue_free()
			#global_position = original_position
			input = recording[0]
			playback_frame = 1
	return input
	
func spawn_clone() -> void:
	# SAFETY: Do not let clones clone.
	if mode != MODE_PLAYER:
		return
	
	var clone := preload("res://player/player.tscn").instantiate()
	clone.global_position = original_position
	clone.recording = recording
	clone.mode = MODE_PLAYBACK
	recording = []
	add_sibling(clone)
	
func _draw() -> void:
	draw_line(Vector2.ZERO, linear_velocity, Color.BLACK, 8)
func _process(delta: float) -> void:
	queue_redraw()
		
var _is_on_floor: float = 0.0
		
func is_on_floor() -> bool:
	return _is_on_floor > 0
	
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	#_is_on_floor = false
	for i in range(0, state.get_contact_count()):
		var normal := state.get_contact_local_normal(i)
		if normal.dot(Vector2.UP) > cos(deg_to_rad(45)):
			_is_on_floor = 3.0 / 60.0
		
	var probe := move_and_collide(Vector2(0, -8), true)
	var probe2 := test_move(transform, Vector2(0, -8))
	if probe != null and probe.get_normal().dot(Vector2.UP) > 0.9:
		_is_on_floor = 3.0 / 60.0

func _physics_process(delta: float) -> void:
	var encoded_inputs := get_inputs()
	if mode == MODE_PLAYER:
		if Input.is_action_just_pressed("clone"):
			if is_recording:
				spawn_clone()
				is_recording = false
			else:
				original_position = global_position
				recording.clear()
				is_recording = true		
		if is_recording:
			recording.push_back(encoded_inputs)
	
	var h_input := encoded_inputs.x
	var jump_pressed := false
	var jump_just_pressed := false
	if encoded_inputs.y == 1:
		jump_pressed = true
		jump_just_pressed = true
	elif encoded_inputs.y == 2:
		jump_pressed = true

	# Hack for not sliding down ramps: don't add gravity when we're on floor
	# and no inputs are pressed?
	if not is_on_floor():
		# NOTE: Getting rid of the if fixes our jumping problem, but it makes
		# us get pushed in to the ground which is probably worse.
		linear_velocity += get_gravity() * delta
	
	var target_x_vel := h_input * H_VEL
	var x_accel: float = sign(target_x_vel - linear_velocity.x) * H_ACCEL
	
	if target_x_vel == 0:
		x_accel *= 0.5
	if not is_on_floor():
		x_accel *= 0.75
	
	var x_accel_integrated = x_accel * delta
	
	if abs(x_accel_integrated) > abs(target_x_vel - linear_velocity.x):
		x_accel_integrated = target_x_vel - linear_velocity.x
	
	linear_velocity.x += x_accel_integrated
	
	if is_on_floor() and jump_just_pressed:
		jump_timer = JUMP_TIME
	if not jump_pressed:
		jump_timer = 0
		
	if jump_timer > 0:
		jump_timer -= delta
		linear_velocity.y = -JUMP_SPEED
	
	if linear_velocity.y > 0:
		# Disable jumps if we ever lose our Y velocity.
		jump_timer = 0
		
	# Manually perform a snap to the floor.
	const SNAP_AMOUNT = 32.0
	if linear_velocity.y > 0:
		var check := move_and_collide(Vector2(0, SNAP_AMOUNT), true)
		if check != null:
			move_and_collide(Vector2(0, SNAP_AMOUNT) - check.get_normal() * 8)
			# _is_on_floor = true
			
	if _is_on_floor > 0:
		_is_on_floor -= delta
			
