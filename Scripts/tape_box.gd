extends Area2D

# Today's tape, sitting by the TV. Interacting puts it in the TV.

@export var tv: Node

@onready var sprite: Sprite2D = $Sprite2D

var _player_inside := false


func _ready() -> void:
	if Day.tape_in:
		queue_free()
		return
	sprite.texture = Day.tape_texture()
	add_to_group(Interactable.GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _player_inside or Dialogue.is_busy():
		return
	if Input.is_action_just_pressed("Interact") and Interactable.is_closest(self):
		Sound.play("tape")
		Dialogue.start(Day.lines("tape"))
		hide()
		set_process(false)
		await Dialogue.finished
		tv.insert_tape()
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
