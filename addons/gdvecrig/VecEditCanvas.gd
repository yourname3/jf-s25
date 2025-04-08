@tool
extends Node2D
class_name VecEditCanvas

var the_drawing: VecDrawing = null
var is_drawn: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()

func _process(delta: float) -> void:
	return
	the_drawing = Engine.get_singleton("GDVecRig").current_vecdrawing
	if the_drawing != null:
		queue_redraw()
	elif is_drawn:
		queue_redraw()
		
func draw_editor_handle(radius, left, mid, right, ls, ms, rs):
	draw_line(left, mid, Color.WHITE)
	draw_line(mid, right, Color.WHITE)
	
	draw_circle(left, radius * 1.1, Color.BLACK)
	draw_circle(left, radius * 0.9, Color.BLUE if ls else Color.WHITE)
	#draw_circle(mid, radius, Color.BLUE if ms else Color.GRAY)
	draw_circle(right, radius * 1.1, Color.BLACK)
	draw_circle(right, radius * 0.9, Color.BLUE if rs else Color.WHITE)
	
func draw_some_center_handle_with_color(radius, where, color, constraint):
	if constraint == VecDrawing.ConstraintType.SAME_ANGLE_AND_LENGTH:
		draw_circle(where, radius, color)
	elif constraint == VecDrawing.ConstraintType.SAME_ANGLE:
		var r = Vector2(radius, radius)
		draw_rect(Rect2(where - r, r * 2), color)
	elif constraint == VecDrawing.ConstraintType.NONE:
		var points = PackedVector2Array()
		radius *= 1.1
		points.push_back(where + Vector2(0, radius))
		points.push_back(where + Vector2(-radius, 0))
		points.push_back(where + Vector2(0, -radius))
		points.push_back(where + Vector2(radius, 0))
		draw_polygon(points, PackedColorArray([color, color, color, color]))
	
func draw_editor_center_handle(radius, mid, ms, constraint):
	var color = Color.BLUE if ms else Color.GRAY
	draw_some_center_handle_with_color(radius * 1.2, mid, Color.BLACK, constraint)
	draw_some_center_handle_with_color(radius, mid, color, constraint)
	
func draw_editor_weights(radius, left, mid, right, ls, ms, rs, constraint):
	draw_line(left, mid, Color.WHITE)
	draw_line(mid, right, Color.WHITE)
	
	draw_circle(left, radius * 0.9, Color(ls, ls, ls))
	#draw_circle(mid, radius, Color(ms, ms, ms))
	draw_some_center_handle_with_color(radius, mid, Color(ms, ms, ms), constraint)
	draw_circle(right, radius * 0.9, Color(rs, rs, rs))
	
func draw_lasso(plugin: GDVecRig, zoom: float):
	var radius = 1.0 / zoom
	if plugin.lasso_points.size() >= 2:
		draw_polyline(plugin.lasso_points, Color.WHITE, radius)
		draw_line(plugin.lasso_points[plugin.lasso_points.size() - 1], plugin.lasso_points[0], Color.GRAY, radius)

func _draw():
	if the_drawing != null:
		the_drawing._do_ui_draw(self)
		is_drawn = true
	else:
		is_drawn = false
