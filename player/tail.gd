extends Bone2D
class_name TailPhysics

@onready var _last_position: Vector2 = global_position

@onready var _rot_min: float = rotation - 0.3
@onready var _rot_max: float = rotation + 0.3
@onready var _rot_center: float = rotation

func _physics_process(delta: float) -> void:
	return # TODO
	var pos := global_position
	var ppos: Vector2 = get_parent().global_position
	
	var pos_rel := pos - ppos
	var lpos_rel := _last_position - ppos
	
	var angle = lpos_rel.angle_to(pos_rel)
	rotation += angle * delta
	rotation += (_rot_center - rotation) * delta
	rotation = clamp(rotation, _rot_min, _rot_max)

	_last_position = pos
