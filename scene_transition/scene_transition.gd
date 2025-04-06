extends CanvasLayer
class_name SceneTransitionScript

var current_next: PackedScene = null

func change_to(scene: PackedScene) -> void:
	if current_next == null:
		current_next = scene
		$AnimationPlayer.play("transition")

func _do_change_now() -> void:
	get_tree().change_scene_to_packed(current_next)
	current_next = null
