extends Camera2D

var target: Player = null

func _ready() -> void:
	# This script should only exist in the level.
	target = get_node("../Player")
	# Make sure we process after the player.
	process_priority = 10
	
func _process(delta: float) -> void:
	var pos: Vector2 = target.global_position
	var height = get_viewport_rect().size.y / zoom.y
	var max_y = Global.bottom_y - height * 0.5
	var min_y = Global.top_y + height * 0.5
	
	print(pos.y, " " , max_y, " ", height)
	
	if pos.y > max_y and pos.y < min_y:
		pos.y = (min_y + max_y) / 2
	elif pos.y > max_y:
		pos.y = max_y
	elif pos.y < min_y:
		pos.y = min_y
		
	global_position = pos
	
	
