extends Node
class_name LevelsScript

var levels = [
	preload("res://levels/level_intro.tscn"),
	preload("res://levels/level_clone_intro.tscn"),
	preload("res://levels/level_crazy_platforming.tscn"),
	preload("res://levels/level_multi_button.tscn"),
	preload("res://levels/level_boost_yourself.tscn")
]

var current_level: int = 0

func get_level_scene():
	if current_level < levels.size():
		return levels[current_level]
	else:
		# Last level (should be a victory screen or something)
		return levels[levels.size() - 1]

func to_current_level():
	SceneTransition.change_to(get_level_scene())

func reload_current():
	SceneTransition.change_to(load(get_tree().current_scene.scene_file_path))#get_level_scene())
	
func next_level():
	if SceneTransition.current_next == null:
		current_level += 1
		SceneTransition.change_to(get_level_scene())
	
