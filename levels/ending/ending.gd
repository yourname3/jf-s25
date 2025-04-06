extends Control
class_name Ending

func _ready() -> void:
	$play_button.pressed.connect(func():
		Levels.current_level = 0
		Sounds.play_music(false)
		SceneTransition.change_to(preload("res://main_menu/main_menu.tscn"))
		)
