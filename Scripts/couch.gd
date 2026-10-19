extends Area2D

# Her spot in front of the TV. She only eats here, and only with her tape on.
# Eating sets off the TV's eye.

@export var tv: Node

var _player_inside := false


func _ready() -> void:
	add_to_group(Interactable.GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _player_inside or Dialogue.is_busy():
		return
	if not Input.is_action_just_pressed("Interact") or not Interactable.is_closest(self):
		return
	if Day.ate:
		Dialogue.start(Day.lines("couch_after"))
	elif not Day.has_food:
		Dialogue.start(Day.lines("couch"))
	elif not Day.tape_in:
		Dialogue.start(Day.lines("food_refuse"))
	else:
		Day.has_food = false
		Day.ate = true
		Dialogue.start(Day.lines("eat"))
		await Dialogue.finished
		tv.play_eye()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
