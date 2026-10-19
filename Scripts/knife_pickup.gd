extends Area2D

# The knife on the kitchen counter. Standing in this area and pressing
# Interact gives the player the knife. Gone for good once taken.

var _player_inside := false


func _ready() -> void:
	if Player.has_knife:
		queue_free()
		return
	add_to_group(Interactable.GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _player_inside or Dialogue.is_busy():
		return
	if Input.is_action_just_pressed("Interact") and Interactable.is_closest(self):
		# Not until the TV says so.
		if not Day.eye_spoke:
			Dialogue.start(Day.lines("knife_locked"))
			return
		Player.has_knife = true
		Sound.play("item")
		Dialogue.start(Day.lines("knife_take"))
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
