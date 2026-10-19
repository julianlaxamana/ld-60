extends Area2D

# The living room TV. Shows static once today's tape is in. When the player
# eats in front of it, the static cuts out and the eye opens and talks. On the
# last day the final tape plays instead, and the game ends.

const OFF := preload("res://Sprites/tv off.png")
const BLACK := preload("res://Sprites/tv black.png")
const SQUINT := preload("res://Sprites/tv eye squint.png")
const EYE_OPEN := preload("res://Sprites/tv eye open.png")
const STATIC: Array[Texture2D] = [
	preload("res://Sprites/tv static 1.png"),
	preload("res://Sprites/tv static 2.png"),
	preload("res://Sprites/tv static 3.png"),
]
const STATIC_FPS = 12.0

@export var screen: Sprite2D

var _player_inside := false
var _static_time := 0.0
# Set while a cutscene owns the screen, so the static stops animating.
var _cutscene := false


func _ready() -> void:
	add_to_group(Interactable.GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	screen.texture = BLACK if Day.eye_spoke else OFF


func _process(delta: float) -> void:
	var showing_static := Day.tape_in and not Day.eye_spoke and not _cutscene
	Sound.set_loop("static", showing_static)
	if showing_static:
		_static_time += delta
		screen.texture = STATIC[int(_static_time * STATIC_FPS) % STATIC.size()]

	if not _player_inside or _cutscene or Dialogue.is_busy():
		return
	if Input.is_action_just_pressed("Interact") and Interactable.is_closest(self):
		if Day.eye_spoke:
			Dialogue.start(Day.lines("tv_after"))
		elif Day.tape_in:
			Dialogue.start(Day.lines("static"))
		else:
			Dialogue.start(Day.lines("tv_off"))


# Called by the tape box once the tape is in.
func insert_tape() -> void:
	Day.tape_in = true
	if Day.is_last_day():
		_play_final_tape()
	else:
		Sound.play("tv_on")


# Called by the couch once the player has eaten.
func play_eye() -> void:
	_cutscene = true
	var player := _player()
	player.can_move = false
	Sound.mute_music(true)
	Sound.play("glitch")
	screen.texture = BLACK
	await _wait(1.5)
	screen.texture = SQUINT
	await _wait(0.6)
	Sound.play("eye_open")
	screen.texture = EYE_OPEN
	await _wait(0.4)
	Dialogue.start(Day.lines("eye"))
	await Dialogue.finished
	screen.texture = SQUINT
	await _wait(0.3)
	Sound.play("tv_off")
	screen.texture = BLACK
	Sound.mute_music(false)
	Day.eye_spoke = true
	_cutscene = false
	player.can_move = true


func _play_final_tape() -> void:
	_cutscene = true
	_player().can_move = false
	Sound.mute_music(true)
	Sound.play("tv_on_final")
	for i in 12:
		screen.texture = STATIC[i % STATIC.size()]
		await _wait(1.0 / STATIC_FPS)
	screen.texture = BLACK
	await _wait(1.0)
	Dialogue.start(Day.lines("final_tape"))
	await Dialogue.finished
	Sound.play("ending")
	screen.texture = OFF
	await _wait(1.0)
	Day.finish()


func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds).timeout


func _player() -> Player:
	return get_tree().current_scene.get_node("CharacterBody2D") as Player


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
