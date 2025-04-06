extends Control
class_name MainMenu

func _ready() -> void:
	$play_button.pressed.connect(func():
		Levels.current_level = 0
		Levels.reload_current()
		)
