extends CharacterBody2D
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
	
func _do_move_and_slide_override(delta: float, override: Vector2) -> void:
	var prev_velocity := velocity
	velocity = override
	_do_move_and_slide(delta)
	velocity = prev_velocity
	
func _draw() -> void:
	draw_line(Vector2.ZERO, velocity, Color.BLACK, 8)
func _process(delta: float) -> void:
	queue_redraw()
	Engine.set_time_scale(0.5)

func _do_move_and_slide(delta: float) -> void:
	if mode == MODE_PLAYBACK:
		print("want to move: ", velocity * delta)
	
	# First move carried objects.
	if velocity.y < 0:
		for object in $DetectOtherPlayers.get_overlapping_bodies():
			if object == self:
				continue
			if object is Player:
				var last_obj = object.position
				#object.velocity.y = 0 #velocity.y
				#object.move_and_collide(velocity * delta * 0.5)
				#object._do_move_and_slide_override(delta, velocity)
				object.move_and_collide(delta * velocity)
				print("moved blocker: ", (object.position - last_obj), " attempted: ", velocity * delta)
	
	var last = position
	move_and_slide()
	if mode == MODE_PLAYBACK:
		print("actually moved: ", (position - last))
	
	#if mode == MODE_PLAYER:
		#move_and_slide() # TODO
		#return
	#
	#if mode == MODE_PLAYBACK:
		#print("_do_move_and_slide: velocity = ", velocity)
	#var prev_position := position
	#var prev_velocity := velocity
	##var retries = 4
	##while retries > 0:
	#move_and_slide()
	#var do_retry := false
	#for i in range(0, get_slide_collision_count()):
		#if mode == MODE_PLAYBACK:
			#print("got col ", i, " ", get_slide_collision(i).get_collider())
		#var col := get_slide_collision(i)
		#var collider := col.get_collider()
		#if collider is Player:
			#if prev_velocity.y < 0:
				#print("retry: ", prev_velocity)
				#if collider.velocity.y > 0:
					#collider.velocity.y = 0
				#collider._do_move_and_slide_override(delta, col.get_remainder())
				##collider.move_and_collide(prev_velocity * delta)
				#do_retry = true
	#
	#if do_retry:
		## Reset position velocity
		#position = prev_position
		#velocity = prev_velocity
		#move_and_slide()
		##retries -= 1
		

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

	velocity += get_gravity() * delta
	
	var target_x_vel := h_input * H_VEL
	var x_accel: float = sign(target_x_vel - velocity.x) * H_ACCEL
	
	if target_x_vel == 0:
		x_accel *= 0.5
	if not is_on_floor():
		x_accel *= 0.75
	
	var x_accel_integrated = x_accel * delta
	
	if abs(x_accel_integrated) > abs(target_x_vel - velocity.x):
		x_accel_integrated = target_x_vel - velocity.x
	
	velocity.x += x_accel_integrated
	
	if is_on_floor() and jump_just_pressed:
		jump_timer = JUMP_TIME
	if not jump_pressed:
		jump_timer = 0
		
	if jump_timer > 0:
		jump_timer -= delta
		velocity.y = -JUMP_SPEED
	
	# floor_max_angle = deg_to_rad(15)
	# move_and_slide()
	_do_move_and_slide(delta)
	
	if velocity.y > 0:
		# Disable jumps if we ever lose our Y velocity.
		jump_timer = 0
