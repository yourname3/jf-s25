extends Node
class_name SoundsScript

@onready var game_music = $Game
@onready var menu_music = $Menu

@onready var magic = $Magic
@onready var magic_fire = $MagicFire
@onready var machine = $Machine
@onready var click = $Click
@onready var click2 = $Click2
@onready var black_hole = $BlackHole
@onready var jump = $Jump

var enable_magic: bool = false
var _did_enable_magic: bool = false

var magic_nrg = 0.0
@onready var magic_base_nrg = db_to_linear(magic.volume_db)

var game_music_nrg = 0.0
var menu_music_nrg = 1.0

var in_game: bool = false

func _ready() -> void:
	menu_music.play()
	# play_music(true) # REMOVE THIS BEFORE SHIPPING

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
	
	var magic_tar = 0.0
	
	if enable_magic:
		magic_tar = 1.0
		if not _did_enable_magic:
			magic.play()
	_did_enable_magic = enable_magic
	magic_nrg += (magic_tar - magic_nrg) * Global.get_lerp(0.1, delta)
	
	magic.volume_db = linear_to_db(magic_nrg * magic_base_nrg)
