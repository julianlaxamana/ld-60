extends StaticBody2D

# The bed. The first time the room loads, the player is asleep in it, wakes up,
# then climbs out and gets control. Coming back through a door skips this.

const SLEEP_TEX := preload("res://Sprites/bed sleep.png")
const AWAKE_TEX := preload("res://Sprites/bed awake.png")
const EMPTY_TEX := preload("res://Sprites/bed empty.png")

const SLEEP_TIME = 1.5
const AWAKE_TIME = 1.2

@export var player: Player

static var played := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if played:
		sprite.texture = EMPTY_TEX
		return
	played = true
	play()


func play() -> void:
	player.can_move = false
	player.hide()
	sprite.texture = SLEEP_TEX
	# Starting a new day: wait until the day card has faded out.
	if Day.is_busy():
		await Day.faded_in
	await get_tree().create_timer(SLEEP_TIME).timeout
	sprite.texture = AWAKE_TEX
	await get_tree().create_timer(AWAKE_TIME).timeout
	sprite.texture = EMPTY_TEX
	player.show()
	player.can_move = true
	Dialogue.start(Day.lines("wake"))
