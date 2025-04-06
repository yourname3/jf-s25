extends Control
class_name RecorderUI

var show_playback: bool = true

var current_player: Player = null
var current_clone: Player = null

@onready var playhead = $bar1/bar2/bar_record/playhead
@onready var rec_indicator = $recording

@onready var bar_record = $bar1/bar2/bar_record

func _ready() -> void:
	Global.recorder_ui = self
	
func render_playback() -> void:
	if current_clone == null:
		return
	
	var progress = float(current_clone.playback_frame) / float(current_clone.recording.size())
	playhead.anchor_left = progress
	playhead.anchor_right = progress
	
func _process(delta: float) -> void:
	#if show_playback:
		
	
	var bar_size = 0.0
	if current_player.is_recording:
		bar_size = (current_player.recording.size() - current_player.recording_start)
		playhead.anchor_left = 1.0
		playhead.anchor_right = 1.0
	elif current_clone != null:
		bar_size = (current_clone.recording.size())
		render_playback()
	else:
		bar_size = (current_player.recording.size() - current_player.recording_start)
		playhead.anchor_left = 0.0
		playhead.anchor_right = 0.0
	bar_size /= float(60 * 8)
	#print(bar_size)
	bar_record.anchor_right = clamp(bar_size, 0.0, 1.0)
		
	rec_indicator.visible = current_player.is_recording
