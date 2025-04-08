extends FastVecDrawing

#func _process(delta: float) -> void:
	##print(waypoints)
	##queue_redraw()
	#for wp in waypoints:
		#wp.compute_value(null, {})
	##print(strokes)

func compute(p0, p1, p2, p3, t):
	var zt = 1 - t
	return \
		(zt * zt * zt * p0) + \
		(3 * zt * zt * t * p1) + \
		(3 * zt * t * t * p2) + \
		(t * t * t * p3);

#func _draw():
	#var computed_points: PackedVector2Array = PackedVector2Array()
#
	## < - > < - >
	## 0 1 2 3 4 5
	##   0 1 2 3
	## (i + 3) <= length -> gives us two handles + two control points
#
	#var i = 1
	#while (i + 3) <= waypoint_count():
		#var p0 := get_waypoint_place(i)
		#var p1 := get_waypoint_place(i + 1)
		#var p2 := get_waypoint_place(i + 2)
		#var p3 := get_waypoint_place(i + 3)
		#
		#print(" -- ", p0, " ", p1, " ", p2, " ", p3)
		#print(" -- ", get_waypoint(i).value, " ", get_waypoint(i + 1).computed_value)
		#
		#for j: int in range(0, steps):
			#var t: float = j / float(steps)
			## Don't subtract -- steps - 1 -- because then we end up with dupe
			## points (as each range is [0.0, 1.0]).
			## TODO: RIght now, we have no logic for getting one curve at the
			## end to render at 1.0. That's probably not the end of the world,
			## but it's something to consider.
			#computed_points.push_back(compute(p0, p1, p2, p3, t))
		#if (i + 3 + 3) > waypoint_count() and not cyclic:
			## If the next loop doesn't exist, then compute the t = 1.0.
			## Also, don't compute it if we're cyclic.
			#computed_points.push_back(compute(p0, p1, p2, p3, 1.0))
		#i += 3
		#
	#if cyclic:
		#if waypoint_count() >= 6:
			#var end := waypoint_count() - 2
			#var p0 := get_waypoint_place(end + 0)
			#var p1 := get_waypoint_place(end + 1)
			#var p2 := get_waypoint_place(0)
			#var p3 := get_waypoint_place(1)
			#for j: int in range(0, steps):
				#var t: float = j / float(steps)
				#computed_points.push_back(compute(p0, p1, p2, p3, t))
		#
	#if do_fill and computed_points.size() >= 3:	
		#draw_colored_polygon(computed_points, fill)
	#for stroke in strokes:
		#stroke.points = computed_points
