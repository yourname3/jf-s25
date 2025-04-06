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

var state: int = 0
const STATE_NORMAL = 0
const STATE_TOUCHED_GOAL = 1

var original_position: Vector2
@onready var animator: PlayerAnimation = $pivot/pony

@onready var player_jump_detector = $PlayerJumpDetector

func _ready() -> void:
	original_position = global_position
	
	if mode == MODE_PLAYER:
		Global.recorder_ui.current_player = self
	else:
		Global.recorder_ui.current_clone = self

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
	
var current_clone: Player = null
	
func spawn_clone() -> void:
	# SAFETY: Do not let clones clone.
	if mode != MODE_PLAYER:
		return
	
	if current_clone != null:	
		current_clone.queue_free()
	
	var clone := preload("res://player/player.tscn").instantiate()
	clone.global_position = original_position
	clone.recording = recording
	clone.mode = MODE_PLAYBACK
	recording = []
	add_sibling(clone)
	current_clone = clone
	
#func _draw() -> void:
	#draw_line(Vector2.ZERO, linear_velocity, Color.BLACK, 8)
#func _process(delta: float) -> void:
	#queue_redraw()
		
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
	
	if player_jump_detector.has_overlapping_bodies():
		_is_on_floor = 3.0 / 60.0
	
# Hystersis for the walking animation. Increase this when we're definitely walking,
# decrease it when we're definitely not.
var walking_accumulator: float = 0.0
var air_accumulator: float = 0.0

# In pixels/second
const WALK_BASE_SPEED = (101 - 29)

# Goal that we are animating to.
var towards_goal: Goal = null

func on_goal(goal: Goal) -> void:
	towards_goal = goal
	

func _physics_process(delta: float) -> void:
	if towards_goal != null:
		linear_velocity = Vector2.ZERO
		var next := global_position.move_toward(towards_goal.global_position, delta * 512.0)
		var offset = next - global_position
		#print(offset)
		move_and_collide(offset)
		#print(global_position, towards_goal.global_position)
		#scale = scale.move_toward(Vector2.ZERO, delta)
		animator.scale = animator.scale.move_toward(Vector2.ZERO, 0.5 * delta)
		towards_goal.scale = towards_goal.scale.move_toward(Vector2.ZERO, 0.9 * delta)
		if towards_goal.scale.length() < 0.0001:
			Levels.next_level()
		return
	
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
	#if not is_on_floor():
		# NOTE: Getting rid of the if fixes our jumping problem, but it makes
		# us get pushed in to the ground which is probably worse.
	linear_velocity += get_gravity() * delta
	#else:
		#linear_velocity += get_gravity() * delta * 0.2
	
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
			
	# Choose animation.
	#var anim = "idle"
	#if is_on_floor():
	if abs(linear_velocity.x) > 32:
		walking_accumulator += delta
	else:
		walking_accumulator -= delta * 3.0
		
	if not is_on_floor():
		if linear_velocity.y < -32:
			air_accumulator += delta * 8.0
		air_accumulator += delta
	else:
		air_accumulator -= delta * 3.0
	
	air_accumulator = clamp(air_accumulator, -0.1, 0.1)
			#
		#if walking_accumulator > 0:
			#anim = "walk"
	walking_accumulator = clamp(walking_accumulator, -0.1, 0.1)
	#print(walking_accumulator)
	#animator.set_animation(anim)
	# For no foot sliding, do this: But it is very slow and not compatible with
	# fast movement speeds.
	# If we can get a gallop animation, we can make it look better.
	# For now, just do foot sliding.
	# animator.set_walkvel(abs(linear_velocity.x) / WALK_BASE_SPEED)
	animator.want_air = air_accumulator > 0
	animator.want_walk = walking_accumulator > 0
	#print(animator.want_walk)
	animator.want_jump_down = linear_velocity.y > 0
	animator.set_walkvel(abs(linear_velocity.x) / (WALK_BASE_SPEED * 6))
			
	if _is_on_floor > 0:
		_is_on_floor -= delta
	
	if global_position.y > Global.bottom_y:
		Levels.reload_current()
	
	#if Input.is_action_just_pressed("jump"):
		#SceneTransition.change_to(preload("res://level/level.tscn"))
	
			
