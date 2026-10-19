extends Node

# Autoloaded as "Sound". Picks the music and background ambience for the
# current room (and day), and plays sound effects.
#
#   Sound.play("item")              # one-shot
#   Sound.set_loop("static", true)  # loops until turned off or the room changes
#   Sound.mute_music(true)          # fade the music out for a cutscene

const DIR := "res://LD60 Music/"
const FADE_TIME = 1.2
const MUSIC_DB = -6.0
const AMBIENCE_DB = -18.0

const TITLE_SCENE := "res://Scenes/title_screen.tscn"
const INTRO_SCENE := "res://Scenes/transition1.tscn"
const HOUSE_SCENES: Array[String] = [
	"res://Scenes/map.tscn",
	"res://Scenes/room2.tscn",
	"res://Scenes/kitchen.tscn",
]
const FOREST_SCENE := "res://Scenes/forest.tscn"
const FOREST2_SCENE := "res://Scenes/forest2.tscn"

const TITLE := "Title screen/LD60_Title_Screen1.wav"
# The title after the ending has been seen once.
const TITLE_AFTER := "Title screen/TS_Bitcrushed.wav"

# Music for each day. The same tracks, more crushed every loop. The last day
# has no music, just the clock.
const HOUSE: Array[String] = [
	"BGM1/LD60_BGM1.wav",
	"BGM1/BGM1_Crushed.wav",
	"BGM1/BGM1_Crushed_2.wav",
	"",
]
const FOREST: Array[String] = [
	"BGM2/BGM2/LD60_BGM2.wav",
	"BGM2/BGM2/BGM2_Crushed.wav",
	"BGM2/BGM2/BGM2_Crushed_2.wav",
]
const FOREST2: Array[String] = [
	"BGM2/BGM2_Extend_1/LD60_BGM2_Extend.wav",
	"BGM2/BGM2_Extend_1/BGM2_E1_Crushed.wav",
	"BGM2/BGM2_Extend_1/BGM2_E1_C2.wav",
]

const CLOCK := "SFXs/clock.mp3"
const WIND := "SFXs/wind.mp3"
const RAIN := "SFXs/Rain.mp3"

# name: [file or files to pick from, volume_db]
const SFX := {
	"start": ["SFXs/Magic2.wav", -6.0],
	"item": ["SFXs/Item1.wav", -4.0],
	"tape": ["SFXs/tape-insersion.mp3", 0.0],
	"tv_on": ["SFXs/shutdown + turn up (s)/turn on2.mp3", -4.0],
	"tv_on_final": ["SFXs/shutdown + turn up (s)/turn on.mp3", -4.0],
	"glitch": ["SFXs/shutdown + turn up (s)/glitch.mp3", -4.0],
	"eye_open": ["SFXs/Magic1.wav", -6.0],
	"tv_off": ["SFXs/shutdown + turn up (s)/machine shutdown.mp3", -6.0],
	"ending": ["SFXs/shutdown + turn up (s)/shutdown3.mp3", -4.0],
	"hurt": ["SFXs/Cry2.wav", -4.0],
	"spider_hurt": [["SFXs/Monster (die_ SFX)/Monster2.wav", "SFXs/Monster (die_ SFX)/Monster9.wav"], -6.0],
	"spider_die": ["SFXs/Monster (die_ SFX)/Growl.wav", -4.0],
	"gate": ["SFXs/Gate2.wav", -4.0],
	"new_day": ["SFXs/Bell1.wav", -6.0],
	"boss_roar": ["SFXs/Monster (die_ SFX)/Monster8.wav", -2.0],
	"boss_laugh": ["SFXs/Laugh.wav", -4.0],
}

const LOOPS := {
	"steps_house": ["SFXs/Walking.mp3", -10.0],
	"steps_grass": ["SFXs/walk on grass.mp3", -8.0],
	"speak": ["SFXs/creatorshome-video-game-speak-358238.mp3", -16.0],
	"static": ["SFXs/shutdown + turn up (s)/TV_static.mp3", -16.0],
}

# Set once the ending has played, for the rest of the session.
var ending_seen := false

var _scene: Node
# "music" / "ambience" -> the AudioStreamPlayer playing it, and its file.
var _channels := {}
var _tracks := {}
var _music_muted := false
var _loops := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene:
		_scene = scene
		stop_loops()
		_pick_tracks(scene)
	# Nothing walks or talks while the screen is fading between days.
	if get_tree().paused:
		stop_loops()


func play(sound: String, pitch_jitter := 0.0) -> void:
	var file = SFX[sound][0]
	if file is Array:
		file = file.pick_random()
	var player := _player(file, false)
	player.volume_db = SFX[sound][1]
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()


func set_loop(sound: String, on: bool) -> void:
	if on == _loops.has(sound):
		return
	if on:
		var player := _player(LOOPS[sound][0], true)
		player.volume_db = LOOPS[sound][1]
		player.play()
		_loops[sound] = player
	else:
		_loops[sound].queue_free()
		_loops.erase(sound)


func stop_loops() -> void:
	for sound in _loops.keys():
		set_loop(sound, false)


# Grass outside, floorboards inside.
func footsteps(on: bool) -> void:
	var outside := _is_outside()
	set_loop("steps_grass", on and outside)
	set_loop("steps_house", on and not outside)


func mute_music(muted: bool) -> void:
	_music_muted = muted
	if _channels.has("music"):
		_fade(_channels["music"], _music_volume(), false)


func _pick_tracks(scene: Node) -> void:
	if scene == null:
		return
	var path := scene.scene_file_path
	var day: int = Day.day
	if path == TITLE_SCENE or path == INTRO_SCENE:
		_set_track("music", TITLE_AFTER if ending_seen else TITLE)
		_set_track("ambience", "")
	elif path in HOUSE_SCENES:
		_set_track("music", HOUSE[mini(day, HOUSE.size()) - 1])
		_set_track("ambience", CLOCK)
	elif path == FOREST_SCENE or path == FOREST2_SCENE:
		var tracks := FOREST if path == FOREST_SCENE else FOREST2
		_set_track("music", tracks[mini(day, tracks.size()) - 1])
		_set_track("ambience", RAIN if day >= 3 else WIND)
	# Any other scene (tests, etc.) keeps whatever was already playing.


# Crossfades `channel` over to `file`. "" fades it out.
func _set_track(channel: String, file: String) -> void:
	if _tracks.get(channel, "") == file:
		return
	_tracks[channel] = file
	if _channels.has(channel):
		_fade(_channels[channel], -80.0, true)
		_channels.erase(channel)
	if file == "":
		return
	var player := _player(file, true)
	player.volume_db = -80.0
	player.play()
	_channels[channel] = player
	_fade(player, _music_volume() if channel == "music" else AMBIENCE_DB, false)


func _music_volume() -> float:
	return -80.0 if _music_muted else MUSIC_DB


func _player(file: String, looping: bool) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(DIR + file)
	add_child(player)
	if looping:
		player.finished.connect(player.play)
	else:
		player.finished.connect(player.queue_free)
	return player


func _fade(player: AudioStreamPlayer, to_db: float, free_after: bool) -> void:
	var tween := player.create_tween()
	tween.tween_property(player, "volume_linear", db_to_linear(to_db), FADE_TIME)
	if free_after:
		tween.tween_callback(player.queue_free)


func _is_outside() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path in [FOREST_SCENE, FOREST2_SCENE]
