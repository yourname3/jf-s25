@tool
extends Node2D
class_name VecDrawing

@export var cyclic: bool = false

@export var fill: Color = Color.WHITE
@export var do_fill: bool = true
@export_range(1, 256) var steps: int = 10

@export var show_rest: bool = true
@export var always_show_points: bool = false

var waypoints = [VecWaypoint]
var strokes = [VecStroke]

@export_node_path("Skeleton2D") var skeleton
@onready var skeleton_node = get_skeleton_from_tree()

const CURRENT_INTERNAL_MODE := InternalMode.INTERNAL_MODE_DISABLED

enum ConstraintType {
	NONE,
	SAME_ANGLE,
	SAME_ANGLE_AND_LENGTH
}

@export var constraints = []
	
func constrain_waypoint_in_editing(target: VecWaypoint, effector: VecWaypoint, center: VecWaypoint, constraint: ConstraintType):
	if constraint == ConstraintType.NONE:
		return
		
	if constraint == ConstraintType.SAME_ANGLE:
		var vec1 = target.value - center.value
		var vec2 = effector.value - center.value
		
		# Use the direction from the effector, normalized, but
		# use our original length.
		vec1 = vec2.normalized() * vec1.length() * -1
		target.value = center.value + vec1
		return
		
	if constraint == ConstraintType.SAME_ANGLE_AND_LENGTH:
		var vec2 = effector.value - center.value
		
		# Literally use the flipped vec2 for the new direction.
		target.value = center.value - vec2
		return

func update_edit_constraint(index, plugin: GDVecRig, cache: Dictionary, force_equal_radius: bool):
	var left_index = index * 3
	var center_index = index * 3 + 1
	var right_index = index * 3 + 2
	
	var left = waypoints[left_index]
	var center = waypoints[center_index]
	var right = waypoints[right_index]
	
	var left_edited = (left_index) in plugin.point_selection
	var center_edited = (center_index) in plugin.point_selection
	var right_edited = (right_index) in plugin.point_selection
	
	var current_contraint = constraints[index]
	if force_equal_radius:
		current_contraint = ConstraintType.SAME_ANGLE_AND_LENGTH
	
	# If both sides are edited, our transformations should *generally*
	# preserve constraints. TODO: Maybe add a second pass to even
	# correct those that don't work..?
	#
	# Also, it doesn't seem like whether the center is edited can really
	# matter.
	if center_edited:
		if left_edited and right_edited:
			return
			
		if left_edited:
			constrain_waypoint_in_editing(right, left, center, current_contraint)
			return
		
		if right_edited:
			constrain_waypoint_in_editing(left, right, center, current_contraint)
			return
	
		# If no points but the center are edited, then we must re-center the old
		# points onto the new center.
		var edit_vec = center.value - cache[center_index]
		left.value += edit_vec
		right.value += edit_vec
	else:
		# If just one waypoint is edited, we must simply update the other
		# one to match.
		#
		# If both waypoints are edited, and we have any constraint
		# at all, then we must move the center by the edit-vec.
		if left_edited and right_edited:
			if current_contraint == ConstraintType.NONE:
				# No change needed. The user may be trying to make a point
				# (literally).
				return
			if current_contraint == ConstraintType.SAME_ANGLE_AND_LENGTH:
				# In this case, the center is simply the literal center.
				center.value = (left.value + right.value) / 2
				return
			if current_contraint == ConstraintType.SAME_ANGLE:
				# In this case, we'll re-interpolate along the left->right line,
				# this should make this work even if we eventually implement
				# rotation/scaling edits.
				var line = right.value - left.value
				var old_line = cache[right_index] - cache[left_index]
				
				# Note on caching: by definition the center isn't edited,
				# so it won't be in the edit cache. As such, we just use
				# 'center.value' for old center value
				var old_center_value = center.value # instead of cache[center_value]
				
				var old_center_dist = old_center_value - cache[left_index]
				var t = old_center_dist.length() / old_line.length()
				
				# We don't need to normalize the line because the t value represents
				# distance *along* this line.
				var new_offset = line * t
				
				center.value = left.value + new_offset
				return
			# Unimplemented... TODO!
			print("warning: unimplemented ConstraintType!")
			return
			
		# Okay, now we can handle the easy single-handle cases.
		if left_edited:
			constrain_waypoint_in_editing(right, left, center, current_contraint)
			return
		
		if right_edited:
			constrain_waypoint_in_editing(left, right, center, current_contraint)
			return


# This function updates waypoint.value so that all waypoints are obeying their
# current constraint. This does not affect computed_value.
#
# It does not take editing information into consideration; it just averages
# things out.
func compute_constraint_on_value_lossy(index: int):
	var c = constraints[index]
	if c == ConstraintType.NONE:
		return
	
	var left_index = index * 3
	var center_index = index * 3 + 1
	var right_index = index * 3 + 2
	
	var left = waypoints[left_index]
	var center = waypoints[center_index]
	var right = waypoints[right_index]
	
	# Weird case where one point is on the same spot as the center.
	# In that case, all we can do is clamp both that way, if
	# we need SAME_LENGTH.
	if left.value == center.value or right.value == center.value:
		if c == ConstraintType.SAME_ANGLE_AND_LENGTH:
			left.value = center.value
			right.value = center.value
		return
	
	# First step: update waypoints to obey angle rule
	if c == ConstraintType.SAME_ANGLE or c == ConstraintType.SAME_ANGLE_AND_LENGTH:
		var dir1 = left.value - center.value
		var dir2 = right.value - center.value
		
		# Compare the flipped vectors because they should point in opposite
		# directions
		var angle_dif = dir1.angle_to(-dir2)
		
		dir1 = dir1.rotated(angle_dif * 0.5)
		dir2 = dir2.length() * dir1.normalized() * -1
		
		left.value = center.value + dir1
		right.value = center.value + dir2

	# Second step: update to obey length rule
	if c == ConstraintType.SAME_ANGLE_AND_LENGTH:
		var dir1 = left.value - center.value
		var dir2 = right.value - center.value

		var avg_length = (dir1.length() + dir2.length()) * 0.5
		
		dir1 = dir1.normalized() * avg_length
		dir2 = dir2.normalized() * avg_length
		
		left.value = center.value + dir1
		right.value = center.value + dir2
		
# This function behaves exactly the same as compute_constraint_on_value_lossy,
# but it applies to computed_value instead -- so it is used to force constraints
# to apply to rigged drawings.
func compute_constraint_on_computed_value_lossy(index: int):
	var c = constraints[index]
	if c == ConstraintType.NONE:
		return
	
	var left_index = index * 3
	var center_index = index * 3 + 1
	var right_index = index * 3 + 2
	
	var left = waypoints[left_index]
	var center = waypoints[center_index]
	var right = waypoints[right_index]
	
	# Weird case where one point is on the same spot as the center.
	# In that case, all we can do is clamp both that way, if
	# we need SAME_LENGTH.
	if left.computed_value == center.computed_value or right.computed_value == center.computed_value:
		if c == ConstraintType.SAME_ANGLE_AND_LENGTH:
			left.computed_value = center.computed_value
			right.computed_value = center.computed_value
		return
	
	# First step: update waypoints to obey angle rule
	if c == ConstraintType.SAME_ANGLE or c == ConstraintType.SAME_ANGLE_AND_LENGTH:
		var dir1 = left.computed_value - center.computed_value
		var dir2 = right.computed_value - center.computed_value
		
		# Compare the flipped vectors because they should point in opposite
		# directions
		var angle_dif = dir1.angle_to(-dir2)
		
		dir1 = dir1.rotated(angle_dif * 0.5)
		dir2 = dir2.length() * dir1.normalized() * -1
		
		left.computed_value = center.computed_value + dir1
		right.computed_value = center.computed_value + dir2

	# Second step: update to obey length rule
	if c == ConstraintType.SAME_ANGLE_AND_LENGTH:
		var dir1 = left.computed_value - center.computed_value
		var dir2 = right.computed_value - center.computed_value

		var avg_length = (dir1.length() + dir2.length()) * 0.5
		
		dir1 = dir1.normalized() * avg_length
		dir2 = dir2.normalized() * avg_length
		
		left.computed_value = center.computed_value + dir1
		right.computed_value = center.computed_value + dir2
		
		
# Gets the associated Skeleton2D from the 'skeleton' NodePath variable, OR
# returns null if the path is either null or invalid. This is because
# get_node_or_null unfortunately does not like it when the NodePath is null.
func get_skeleton_from_tree() -> Skeleton2D:
	return null if skeleton == null else get_node_or_null(skeleton)

func collect_children():
	waypoints.clear()
	strokes.clear()
	for child in get_children(true):
		if child is VecWaypoint:
			waypoints.push_back(child)
		if child is VecStroke:
			strokes.push_back(child)
	
	var needed_constraints = center_waypoint_count()
	while constraints.size() < needed_constraints:
		constraints.push_back(ConstraintType.SAME_ANGLE)
	if constraints.size() > needed_constraints:
		constraints.pop_back()
	

func get_waypoint(index: int) -> VecWaypoint:
	return waypoints[index]
	
func get_waypoint_place(index: int) -> Vector2:
	if show_rest:
		return waypoints[index].value
	else:
		return waypoints[index].computed_value
	
func waypoint_count() -> int:
	return waypoints.size()
	
func center_waypoint_count():
	return waypoint_count() / 3

func get_plugin() -> GDVecRig:
	return Engine.get_singleton("GDVecRig")

func is_currently_edited():
	var vr: GDVecRig = Engine.get_singleton("GDVecRig")
	return vr.current_vecdrawing == self
	
func edit_point(index: int, offset: Vector2):
	if index < 0 or index >= waypoint_count():
		return
	get_waypoint(index).value += offset
	
func try_starting_editing(plugin: GDVecRig):
	if plugin.point_highlight >= 0:
		plugin.point_edited = true
		if not plugin.point_selection.has(plugin.point_highlight):
			print("select point -> ", plugin.point_highlight)
			# Clear the selection we we're selecitng a new point
			plugin.point_selection.clear()
			add_to_select(plugin, plugin.point_highlight)
		return true
	
	return false
	
func stop_editing(plugin: GDVecRig):
	plugin.point_edited = false
	
func add_to_select(plugin: GDVecRig, point: int):
	if not plugin.point_selection.has(point):
		plugin.point_selection.push_back(point)

func get_idx_ordered_centerlast(idx: int) -> int:
	var base: int = idx / 3
	var offset := idx - (base * 3)
	match offset:
		0:
			offset = 0
		1:
			offset = 2 
		2:
			offset = 1
	return (base * 3) + offset

	
func find_point_index_at_target(radius_factor: int, plugin: GDVecRig, target: Vector2):
	var radius = radius_factor / zoom()
	
	for i in range(0, waypoint_count()):
		var center = get_waypoint_place(i)
		if (target - center).length_squared() <= (radius * radius):
			return i
	return -1
	
func add_to_select_from_target(plugin: GDVecRig, target: Vector2):
	var radius = 5 / zoom()
	
	for i in range(0, waypoint_count()):
		var center = get_waypoint_place(i)
		if (target - center).length_squared() <= (radius * radius):
			add_to_select(plugin, i)
			
func select_in_lasso(plugin: GDVecRig):
	for i in range(0, waypoint_count()):
		var p = get_waypoint_place(i)
		if Geometry2D.is_point_in_polygon(p, plugin.lasso_points):
			add_to_select(plugin, i)
	
func is_selected(index):
	return get_plugin().point_selection.has(index)
	
func zoom():
	return get_viewport().get_screen_transform().get_scale().x
	
func paint_from_target(plugin: GDVecRig, target: Vector2):
	var radius = 10 / zoom()
	
	for i in range(0, waypoint_count()):
		var center = get_waypoint_place(i)
		if (target - center).length_squared() <= (radius * radius):
			get_waypoint(i).edit_weight(plugin.weight_painting_bone, plugin)

func compute_pivot_point(plugin: GDVecRig):
	var point: Vector2 = Vector2.ZERO
	for wp in plugin.point_selection:
		point += waypoints[wp].value
	return point / plugin.point_selection.size()

func handle_editing_mouse_motion(plugin: GDVecRig, event: InputEventMouseMotion):
	if plugin.lasso_started:
		plugin.lasso_points.push_back(get_local_mouse_position())
	elif plugin.point_edited:
		# Store the old value of the points for computing constraints.
		# ALSO: maybe undo support one day..?
		var point_edit_cache = {}
		
		var motion_grab: Vector2 = event.relative / zoom()
		var pivot_point: Vector2 = Vector2.ZERO
		var rotation_amount: float = 0
		var scale_amount: float = 1.0
		
		var do_rotation: bool = false
		var do_scale: bool = false
		
		if event.alt_pressed:
			do_rotation = true
			do_scale = true
		if event.ctrl_pressed:
			do_rotation = true
		
		if do_rotation or do_scale:
			pivot_point = compute_pivot_point(plugin)
			var cur_delta = get_global_mouse_position() - pivot_point
			var prev_delta = (get_global_mouse_position() - event.relative / zoom()) - pivot_point
			# This should work..?
			if do_rotation:
				rotation_amount = prev_delta.angle_to(cur_delta)
			if do_scale:
				scale_amount = cur_delta.length() / prev_delta.length()
		
		for point in plugin.point_selection:
		#print(event.relative / zoom())
			point_edit_cache[point] = waypoints[point].value
			var motion: Vector2 = motion_grab
			if do_rotation or do_scale:
				var v: Vector2 = waypoints[point].value
				v -= pivot_point
				if do_rotation:
					v = v.rotated(rotation_amount)
				# Skip do_scale check because multiplying by 1.0 should not matter
				v *= scale_amount
				v += pivot_point
				motion = v - waypoints[point].value
			edit_point(point, motion)
		for i in range(0, center_waypoint_count()):
			update_edit_constraint(i, plugin, point_edit_cache, event.shift_pressed)
		#queue_redraw()
		return true
	elif plugin.brand_new_point > 0:
		var center = waypoints[plugin.brand_new_point].value
		var delta = get_global_mouse_position() - center
		waypoints[plugin.brand_new_point - 1].value = center - delta
		waypoints[plugin.brand_new_point + 1].value = center + delta
	else:
		var previous_highlight = plugin.point_highlight
		
		var radius = 7 / zoom()
		plugin.point_highlight = -1
		
		for _i in range(0, waypoint_count()):
			var i = get_idx_ordered_centerlast(_i)
			var center = get_waypoint_place(i)
			if (get_local_mouse_position() - center).length_squared() <= (radius * radius):
				plugin.point_highlight = i
				break
			
		if previous_highlight != plugin.point_highlight:
			pass
	return false
	
func delete_entire_points(group_idx: int, plugin: GDVecRig) -> void:
	# We don't want to mess up the selection.
	plugin.point_selection.clear()
	
	var new_points: Array[VecWaypoint] = []
	var idx = 0
	for point in waypoints:
		if idx / 3 != group_idx:
			new_points.append(point)
		else:
			point.free()
		idx += 1
	waypoints = new_points
	
	
func reset_curve_point(idx: int) -> void:
	var base := idx / 3
	waypoints[idx].value = waypoints[(base * 3) + 1].value 

func handle_editing_mouse_button(plugin: GDVecRig, event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if plugin.add_end_point():
				for i in range(0, 3):
					var waypoint = VecWaypoint.new()
					waypoint.value = get_local_mouse_position()
					# NOTE: Apparently internal nodes don't work correctly.
					# Consider changing the Waypoints to be resources..?
					add_child(waypoint)
					waypoint.owner = owner
				
				collect_children()
				plugin.brand_new_point = waypoints.size() - 2
				return true
				
			if plugin.is_in_toggle_constraint():
				var index = find_point_index_at_target(10, plugin, get_local_mouse_position())
				if index >= 0 and index % 3 == 1:
					var c: ConstraintType = constraints[index / 3]
					c = (c + 1) % 3
					constraints[index / 3] = c
				return true
			
			if plugin.is_in_delete():
				var index = find_point_index_at_target(10, plugin, get_local_mouse_position())
				# TODO: Prioritize center waypoints for this. For now, just delete
				# the curve segment no matter which one we hit.
				delete_entire_points(index / 3, plugin)
				#if index >= 0:
					#if index % 3 == 1:
						#delete_entire_points(index / 3, plugin)
					#else:
						#reset_curve_point(index)
				return true
			
			if event.get_modifiers_mask() & KEY_MASK_SHIFT:
				var selected = add_to_select_from_target(plugin, get_local_mouse_position())
				if not selected and plugin.may_start_lasso():
					plugin.lasso_started = true
				return true
			else:
				var editing = try_starting_editing(plugin)
				if not editing and plugin.may_start_lasso():
					plugin.lasso_started = true
					
				return true
		else:
			if plugin.lasso_started:
				if event.get_modifiers_mask() & KEY_MASK_SHIFT:
					pass # Don't throw out old points
				else:
					# CLear selection
					plugin.point_selection.clear()
				select_in_lasso(plugin)
				plugin.lasso_started = false
				plugin.lasso_points.clear()
			else:
				stop_editing(plugin)
	return false
	
func handle_weight_paint_mouse_motion(plugin: GDVecRig, event: InputEventMouseMotion):
	if plugin.weight_painting_now:
		paint_from_target(plugin, get_local_mouse_position())
		return true
	return false
	
func handle_weight_paint_mouse_button(plugin: GDVecRig, event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			plugin.weight_painting_now = true
		else:
			plugin.weight_painting_now = false
		return true
	return false

func edit_input(plugin: GDVecRig, event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		if plugin.in_mode_weightpaint():
			return handle_weight_paint_mouse_motion(plugin, event)
		else:
			return handle_editing_mouse_motion(plugin, event)
				
	if event is InputEventMouseButton:
		if not event.pressed:
			# Always reset brand new point on new mouse motion.
			plugin.brand_new_point = -1
		
		if plugin.in_mode_weightpaint():
			return handle_weight_paint_mouse_button(plugin, event)
		else:
			return handle_editing_mouse_button(plugin, event)
		
				
	return false

func _ready():
	#var ordered = []
	#for child in get_children(true):
		#if child is VecWaypoint:
			#ordered.push_back(child)
	#
	#for child in ordered:
		#remove_child(child)
	#
	#for child in ordered:
		#add_child(child, false, CURRENT_INTERNAL_MODE)
		#child.owner = owner
	
	collect_children()
	pass # Replace with function body.

var timer_20fps := 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		# Always collect waypoints while being edited.
		collect_children()
		skeleton_node = get_skeleton_from_tree()
		
	# SO... I thought that this hack was sufficient to make the pony not lag
	# the game absurdly.
	# Apparently I was mistaken. We do still need to convert everything to
	# resources...?
	# HAHA JK THE CODE WAS BROKESN
	timer_20fps -= delta
	if timer_20fps > 0:
		return
	else:
		timer_20fps += 1.0 / 20.0
		
	queue_redraw()
	
	# First step: re-compute constraints. Maybe we should have a flag
	# to disable this.
	for i in range(0, center_waypoint_count()):
		compute_constraint_on_value_lossy(i)
	
	# Cache used to speed up bone computations
	var transform_cache = {}
	
	# Second step: compute armature transform
	for i in range(0, waypoint_count()):
		var s = skeleton_node
		if Engine.is_editor_hint() and skeleton != null:
			s = get_node_or_null(skeleton)
		get_waypoint(i).compute_value(s, transform_cache)
	
	# Extremely strange behavior:
	# If this condition is 'skeleton != null', the constraints work
	# in-editor.
	# If this condition is 'skeleton_node != null', the constraints DO NOT
	# work in editor, but the 'print' statement below does go off...?
	if skeleton != null:
		#print("I am computing the values.")
		# Final step: compute the constraints on all the computed values.
		# This is somewhat powerful, it means that armatures can be forced
		# to obey extra constraints.
		for i in range(0, center_waypoint_count()):
			compute_constraint_on_computed_value_lossy(i)
	
#	if Engine.is_editor_hint():
#		print("e")
#		queue_redraw()
	
func compute(p0, p1, p2, p3, t):
	var zt = 1 - t
	return \
		(zt * zt * zt * p0) + \
		(3 * zt * zt * t * p1) + \
		(3 * zt * t * t * p2) + \
		(t * t * t * p3);
	

	
func draw_line_width(points: PackedVector2Array, width: PackedVector2Array):
	pass
	


func _do_ui_draw(canvas: VecEditCanvas) -> void:
	var radius = 5 / zoom()
	var plugin: GDVecRig = get_plugin()
	
	var i := 0

	if is_currently_edited() or always_show_points:
		if plugin.in_mode_weightpaint(): # "In weight painting mode"
			var bone = 0
			i = 0
			while (i + 2) <= waypoint_count():
				var p0 = get_waypoint_place(i)
				var p0s = get_waypoint(i).get_weight(plugin.weight_painting_bone)
				var p1 = get_waypoint_place(i + 1)
				var p1s = get_waypoint(i + 1).get_weight(plugin.weight_painting_bone)
				var p2 = get_waypoint_place(i + 2)
				var p2s = get_waypoint(i + 2).get_weight(plugin.weight_painting_bone)
				canvas.draw_editor_weights(radius, p0, p1, p2, p0s, p1s, p2s, constraints[i / 3])
				
				i += 3
		else:
			i = 0
			while (i + 2) <= waypoint_count():
				var p0 = get_waypoint_place(i)
				var p0s = is_selected(i)
				var p1 = get_waypoint_place(i + 1)
				var p1s = is_selected(i + 1)
				var p2 = get_waypoint_place(i + 2)
				var p2s = is_selected(i + 2)
				canvas.draw_editor_handle(radius, p0, p1, p2, p0s, p1s, p2s)
				canvas.draw_editor_center_handle(radius, p1, p1s, constraints[i / 3])
				
				i += 3
	
	if plugin.lasso_started:
		#print("Yo ", plugin.lasso_points.size())
		canvas.draw_lasso(plugin, zoom())
	
func _draw():
	var computed_points: PackedVector2Array = PackedVector2Array()

	# < - > < - >
	# 0 1 2 3 4 5
	#   0 1 2 3
	# (i + 3) <= length -> gives us two handles + two control points

	var i = 1
	while (i + 3) <= waypoint_count():
		var p0 := get_waypoint_place(i)
		var p1 := get_waypoint_place(i + 1)
		var p2 := get_waypoint_place(i + 2)
		var p3 := get_waypoint_place(i + 3)
		
		for j: int in range(0, steps):
			var t: float = j / float(steps)
			# Don't subtract -- steps - 1 -- because then we end up with dupe
			# points (as each range is [0.0, 1.0]).
			# TODO: RIght now, we have no logic for getting one curve at the
			# end to render at 1.0. That's probably not the end of the world,
			# but it's something to consider.
			computed_points.push_back(compute(p0, p1, p2, p3, t))
		if (i + 3 + 3) > waypoint_count() and not cyclic:
			# If the next loop doesn't exist, then compute the t = 1.0.
			# Also, don't compute it if we're cyclic.
			computed_points.push_back(compute(p0, p1, p2, p3, 1.0))
		i += 3
		
	if cyclic:
		if waypoint_count() >= 6:
			var end := waypoint_count() - 2
			var p0 := get_waypoint_place(end + 0)
			var p1 := get_waypoint_place(end + 1)
			var p2 := get_waypoint_place(0)
			var p3 := get_waypoint_place(1)
			for j: int in range(0, steps):
				var t: float = j / float(steps)
				computed_points.push_back(compute(p0, p1, p2, p3, t))
		
	if do_fill and computed_points.size() >= 3:	
		draw_colored_polygon(computed_points, fill)
	for stroke in strokes:
		stroke.points = computed_points
						
		
