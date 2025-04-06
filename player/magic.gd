extends VecDrawing
class_name PlayerMagic

var roots: Array[Vector2] = []

func _ready() -> void:
	super._ready()
	
	for i in range(0, waypoints.size()):
		roots.push_back(waypoints[i].value)

func _process(delta: float) -> void:
	super._process(delta)
	for i in range(0, roots.size() / 3):
		var dir: Vector2 = waypoints[i * 3 + 2].value - waypoints[i * 3 + 0].value
		var wp: VecWaypoint = waypoints[i * 3 + 1]
		var noise: Vector2 = dir.orthogonal().normalized() * randf_range(-64.0, 64.0)
		var thing = roots[i * 3 + 1] + noise
		wp.value += (thing - wp.value) * Global.get_lerp(0.01, delta)
		wp.computed_value = wp.value
		
		var diff = wp.value - roots[i * 3 + 1]
		waypoints[i * 3 + 0].value = roots[i * 3 + 0] + diff
		waypoints[i * 3 + 0].computed_value = roots[i * 3 + 0] + diff
		
		waypoints[i * 3 + 2].value = roots[i * 3 + 2] + diff
		waypoints[i * 3 + 2].computed_value = roots[i * 3 + 2] + diff
