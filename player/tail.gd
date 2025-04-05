extends Bone2D
class_name TailPhysics

#@onready var _last_position: Vector2 = global_position
#
#@onready var _rot_min: float = rotation - 0.3
#@onready var _rot_max: float = rotation + 0.3
#@onready var _rot_center: float = rotation

var current_offset: Vector2 = Vector2.ZERO
@onready var original_position := position
@onready var original_angle := rotation

var _last_position = global_position

var spring_x: Vector2 = Vector2.ZERO
var spring_v: Vector2 = Vector2.ZERO

const K = 80
const SEP = 0
const B = 4

@onready var ba = get_bone_angle()
@onready var bl = get_length()

func spring_physics(delta: float, parent_x: Vector2) -> void:
	var dir := spring_x - parent_x
	var dist := dir.length()
	var force := Vector2.ZERO
	if dist > 0:
		dir /= dist
		force += -K * (dist - SEP) * dir - B * spring_v
		
	spring_v += force * delta
	spring_x += spring_v * delta
	
	spring_x = spring_x.limit_length(32)
	# print(force)

func _physics_process(delta: float) -> void:
	var p = get_parent()
	
	
	
	if p is TailPhysics:
		spring_physics(delta, p.spring_x)
		
		
	else:
		var spring_zone = _last_position - global_position
		spring_physics(delta, spring_zone)
		_last_position = global_position	
		
	var effector: Vector2 = Vector2.from_angle(ba) * bl
	var to_effector = effector + spring_x
	
	rotation = original_angle + effector.angle_to(to_effector)
		#rotation = original_angle + spring_x.angle()
		#spring_physics(delta, p.spring_x)
		#current_offset = spring_x
		#var target_position = original_position + spring_x
		#var angle = original_position.angle_to(target_position)
		
		#p.rotation = p.original_angle + angle
		#position = original_position + spring_x
		
		
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
