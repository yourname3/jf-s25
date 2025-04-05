extends Bone2D
class_name TailPhysics

#@onready var _last_position: Vector2 = global_position
#
#@onready var _rot_min: float = rotation - 0.3
#@onready var _rot_max: float = rotation + 0.3
#@onready var _rot_center: float = rotation

var current_offset: Vector2 = Vector2.ZERO
@onready var original_position := position

var _last_position = global_position

func _physics_process(delta: float) -> void:
	var p = get_parent()
	if p is TailPhysics:
		current_offset += (p.current_offset - current_offset) * Global.get_lerp(0.3, delta)
		position = original_position + current_offset
	else:
		current_offset = _last_position - global_position
		#var noise_amount = clamp(current_offset.length() / 16.0, 0.0, 1.0)
		#current_offset += current_offset.orthogonal() * noise_amount
		current_offset = current_offset.limit_length(16)
		#print(current_offset)
		_last_position = global_position
		
	#return # TODO
	#var pos := global_position
	#var ppos: Vector2 = get_parent().global_position
	#
	#var pos_rel := pos - ppos
	#var lpos_rel := _last_position - ppos
	#
	#var angle = lpos_rel.angle_to(pos_rel)
	#rotation += angle * delta
	#rotation += (_rot_center - rotation) * delta
	#rotation = clamp(rotation, _rot_min, _rot_max)
#
	#_last_position = pos
