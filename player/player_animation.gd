extends Node2D
class_name PlayerAnimation

@onready var bone_ik_back := $pony/root/ik_back_root
@onready var bone_ik_front := $pony/root/ik_front_root

@onready var body_root := $pony/root/body_root
@onready var body_root_base: float = $pony/root/body_root.position.y

@onready var detect_ik_back := $foot_back
@onready var detect_ik_front := $foot_front

func _ready() -> void:
	$"Pony-color-ref".queue_free()
	$"Pony-ref".queue_free()
	$"Pony-ref2".queue_free()
	
func _physics_process(delta: float) -> void:
	const MAX := 256.0
	
	var back_y := 0.0
	var front_y := 0.0
	
	var valid = true
	
	var col: KinematicCollision2D = detect_ik_back.move_and_collide(Vector2(0, MAX), true)
	if col != null:
		back_y = col.get_travel().y
	else:
		valid = false
	col = detect_ik_front.move_and_collide(Vector2(0, MAX), true)
	if col != null:
		front_y = col.get_travel().y
	else:
		valid = false
	
	if not valid:
		# If both aren't meaningful, don't do anything.
		back_y = 0
		front_y = 0
	
	var avg = (back_y + front_y) / 2
	
	bone_ik_back.position.y = back_y - avg
	bone_ik_front.position.y = front_y - avg
	
	body_root.rotation = atan2(front_y - back_y, detect_ik_front.position.x - detect_ik_back.position.x)
	#body_root.position.y = body_root_base + (back_y + front_y) / 2
	print(body_root.rotation)
	#print(back_y, " ", front_y)
	#print(bone_ik_back.position, " ", bone_ik_front.position)
