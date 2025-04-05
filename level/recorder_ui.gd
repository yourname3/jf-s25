extends Control
class_name RecorderUI

var show_playback: bool = true

var current_player: Player = null
var current_clone: Player = null

@onready var playhead = $bar1/bar2/playhead

func _ready() -> void:
	Global.recorder_ui = self
	
func render_playback() -> void:
	if current_clone == null:
		return
	
	var progress = float(current_clone.playback_frame) / float(current_clone.recording.size())
	playhead.anchor_left = progress
	playhead.anchor_right = progress
	
func _process(delta: float) -> void:
	if show_playback:
		render_playback()
