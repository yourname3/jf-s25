extends Node2D
class_name PlayerAnimation

func _ready() -> void:
	$"Pony-color-ref".queue_free()
	$"Pony-ref".queue_free()
	$"Pony-ref2".queue_free()
