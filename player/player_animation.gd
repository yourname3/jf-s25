extends Node2D
class_name PlayerAnimation

@onready var bone_ik_back := $pony/root/ik_back_root
@onready var bone_ik_front := $pony/root/ik_front_root

@onready var body_root := $pony/root/body_root
@onready var body_root_base: float = $pony/root/body_root.position.y

@onready var detect_ik_back := $foot_back
@onready var detect_ik_front := $foot_front

var player_parent: Player = null

@onready var animation_player := $AnimationPlayer
@onready var tree := $AnimationTree

var want_walk: bool = false
var want_air: bool = false

var walk_blend: float = 0.0
var air_blend: float = 0.0

func target(b: bool) -> float:
	return 1.0 if b else 0.0
	
func set_walkvel(scale: float) -> void:
	tree["parameters/walk_scaler/scale"] = scale
	
func _process(delta: float) -> void:
	var wb_t = target(want_walk)
	var ab_t = target(want_air)
	
	walk_blend = move_toward(walk_blend, wb_t, delta * 3.0)
	air_blend = move_toward(air_blend, ab_t, delta * 2.0)
	
	tree["parameters/blend_to_walk/blend_amount"] = walk_blend
	tree["parameters/blend_to_air/blend_amount"] = air_blend

func _ready() -> void:
	$"Pony-color-ref".queue_free()
	$"Pony-ref".queue_free()
	$"Pony-ref2".queue_free()
	
	if get_parent() != null and get_parent().get_parent() != null:
		var p = get_parent().get_parent()
		if p is Player:
			player_parent = p
	
func _physics_process(delta: float) -> void:
	const MAX := 512.0
	const MAX2 := 128.0
	
	var back_y := 0.0
	var front_y := 0.0
	
	var valid = true
	
	var col: KinematicCollision2D = detect_ik_back.move_and_collide(Vector2(0, MAX), true)
	if col != null:
		back_y = min(col.get_travel().y, MAX2)
	else:
		valid = false
	col = detect_ik_front.move_and_collide(Vector2(0, MAX), true)
	if col != null:
		front_y = min(col.get_travel().y, MAX2)
	else:
		valid = false
	
	if player_parent != null and not player_parent.is_on_floor():
		# This may be less necessary when we have other anims, but still.
		valid = false
	
	if not valid:
		# If both aren't meaningful, don't do anything.
		back_y = 0
		front_y = 0
	
	var avg = (back_y + front_y) / 2
	
	var back_y_target: float = back_y - avg
	var front_y_target: float = front_y - avg
	
	bone_ik_back.position.y += (back_y_target - bone_ik_back.position.y) * Global.get_lerp(0.03, delta)
	bone_ik_front.position.y += (front_y_target - bone_ik_front.position.y) * Global.get_lerp(0.03, delta)
	
	var target_rot: float = atan2(front_y - back_y, detect_ik_front.position.x - detect_ik_back.position.x)
	#body_root.position.y = body_root_base + (back_y + front_y) / 2
	#print(body_root.rotation)
	#print(back_y, " ", front_y)
	#print(bone_ik_back.position, " ", bone_ik_front.position)
	body_root.rotation += (target_rot - body_root.rotation) * Global.get_lerp(0.03, delta)
