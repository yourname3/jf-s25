extends Node

@export_node_path("Node2D")
var target_node_path = NodePath()

@export var flip_bend_direction := false
@export var joint_one_bone_index := -1
@export var joint_two_bone_index := -1

var _angle_a = 0.0
var _angle_b = 0.0


func _process(delta: float) -> void:
	_update_two_bone_ik_angles()


func _update_two_bone_ik_angles():
	assert(joint_one_bone_index != -1)
	assert(joint_two_bone_index != -1)
	
	if target_node_path.is_empty():
		return
	
	var target = get_node(target_node_path) as Node2D
	var bone_a = get_parent().get_bone(joint_one_bone_index)
	var bone_b = get_parent().get_bone(joint_two_bone_index)
	
	var bone_a_len = bone_a.get_length()
	var bone_b_len = bone_b.get_length()
	
	var sin_angle2 = 0.0
	var cos_angle2 = 1.0
	
	_angle_b = 0.0
	
	var cos_angle2_denom = 2.0 * bone_a_len * bone_b_len
	if not is_zero_approx(cos_angle2_denom):
		var target_len_sqr = _distance_squared_between(bone_a, target)
		var bone_a_len_sqr = bone_a_len * bone_a_len
		var bone_b_len_sqr = bone_b_len * bone_b_len
		
		cos_angle2 = (target_len_sqr - bone_a_len_sqr - bone_b_len_sqr) / cos_angle2_denom
		cos_angle2 = clamp(cos_angle2, -1.0, 1.0);
		
		_angle_b = acos(cos_angle2)
		if flip_bend_direction:
			_angle_b = -_angle_b
		
		sin_angle2 = sin(_angle_b)
	
	var tri_adjacent = bone_a_len + bone_b_len * cos_angle2
	var tri_opposite = bone_b_len * sin_angle2
	
	var xform_inv = bone_a.get_parent().global_transform.affine_inverse()
	var target_pos = xform_inv * target.global_position - bone_a.position
	
	var tan_y = target_pos.y * tri_adjacent - target_pos.x * tri_opposite
	var tan_x = target_pos.x * tri_adjacent + target_pos.y * tri_opposite
	_angle_a = atan2(tan_y, tan_x)
	
	var bone_a_angle = bone_a.get_bone_angle()
	var bone_b_angle = bone_b.get_bone_angle()
	bone_a.rotation = _angle_a - bone_a_angle
	bone_b.rotation = _angle_b - angle_difference(bone_a_angle, bone_b_angle)


func _distance_squared_between(node_a: Node2D, node_b: Node2D) -> float:
	return node_a.global_position.distance_squared_to(node_b.global_position)
