extends Node
class_name SoundsScript

@onready var game_music = $Game
@onready var menu_music = $Menu

var game_music_nrg = 0.0
var menu_music_nrg = 1.0

var in_game: bool = false

func _ready() -> void:
	menu_music.play()

func play_music(in_game_: bool) -> void:
	in_game = in_game_
	
	var next_track: AudioStreamPlayer = game_music if in_game else menu_music
	if db_to_linear(next_track.volume_db) < 0.2 or not next_track.playing:
		next_track.play()

func _process(delta: float) -> void:
	var gmt = 1.0 if in_game else 0.0
	
	game_music_nrg += (gmt - game_music_nrg) * Global.get_lerp(0.1, delta)
	menu_music_nrg += ((1.0 - gmt) - menu_music_nrg) * Global.get_lerp(0.1, delta)
	
	game_music.volume_db = linear_to_db(game_music_nrg)
	menu_music.volume_db = linear_to_db(menu_music_nrg)
